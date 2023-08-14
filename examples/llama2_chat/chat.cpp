#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include "common.h"
#include "llama.h"
#include "build-info.h"
#include "chat.h"

#include <cassert>
#include <cinttypes>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#if defined (__unix__) || (defined (__APPLE__) && defined (__MACH__))
#include <signal.h>
#include <unistd.h>
#elif defined (_WIN32)
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <signal.h>
#endif

class ChatSession {
private:
    gpt_params params;
    llama_context_params ctx_params;
    llama_model * model;
    llama_context * ctx;
public:
    ChatSession(std::string model_path) {
        params.model = model_path;
        llama_backend_init(params.numa);
    }

    void load_model() {
        std::tie(model, ctx, ctx_params) = llama_init_from_gpt_params(params);
        // throw exception if model is null
        if (model == NULL) {
            throw std::runtime_error("Unable to load model");
        }
    }

    WrappedChatConverseReturnable Converse(const std::string& input) {  // NOLINT(*)
        try {
            //---------------------------------
            // Tokenize the prompt :
            //---------------------------------
            params.prompt = input;

            std::vector<llama_token> tokens_list;
            tokens_list = ::llama_tokenize( ctx , params.prompt , true );

            const int max_context_size     = llama_n_ctx( ctx );
            const int max_tokens_list_size = max_context_size - 4 ;

            // Throw exception if prompt is too long
            if ( (int)tokens_list.size() > max_tokens_list_size ) {
                throw std::runtime_error("Prompt too long: " + std::to_string(tokens_list.size()) + " tokens, max " +
                std::to_string(max_tokens_list_size));
            }

            //---------------------------------
            // Main prediction loop :
            //---------------------------------

            // The LLM keeps a contextual cache memory of previous token evaluation.
            // Usually, once this cache is full, it is required to recompute a compressed context based on previous
            // tokens (see "infinite text generation via context swapping" in the main example), but in this minimalist
            // example, we will just stop the loop once this cache is full or once an end of stream is detected.

            std::string output = "";

            while ( llama_get_kv_cache_token_count( ctx ) < max_context_size ) {
                //---------------------------------
                // Evaluate the tokens :
                //---------------------------------

                // Throw exception if eval fails
                if ( llama_eval( ctx , tokens_list.data() , int(tokens_list.size()) ,
                                 llama_get_kv_cache_token_count( ctx ) , params.n_threads ) ) {
                    throw std::runtime_error("Failed to eval");
                }

                tokens_list.clear();

                //---------------------------------
                // Select the best prediction :
                //---------------------------------

                llama_token new_token_id = 0;

                auto logits  = llama_get_logits( ctx );
                auto n_vocab = llama_n_vocab( ctx ); // the size of the LLM vocabulary (in tokens)

                std::vector<llama_token_data> candidates;
                candidates.reserve( n_vocab );

                for( llama_token token_id = 0 ; token_id < n_vocab ; token_id++ ) {
                    candidates.emplace_back( llama_token_data{ token_id , logits[ token_id ] , 0.0f } );
                }

                llama_token_data_array candidates_p = { candidates.data(), candidates.size(), false };

                // Select it using the "Greedy sampling" method :
                new_token_id = llama_sample_token_greedy( ctx , &candidates_p );


                // is it an end of stream ?
                if ( new_token_id == llama_token_eos() ) {
                    fprintf(stderr, " [end of text]\n");
                    break;
                }

                // Add new token to outputs
                output += llama_token_to_str(ctx, new_token_id);

                // Push this new token for next evaluation :
                tokens_list.push_back( new_token_id );

            } // wend of main loop


            // Copy output to new memory
            auto outputCopy = new std::string(output);

            // TODO: free ctx here instead of at inference time?

            return {true, "", outputCopy->c_str()};

        } catch (const std::exception& e) {
            return {false, e.what(), ""};
        }
    };

    void reset() {
        // print 'reset'
        llama_free( ctx );
        ctx = llama_new_context_with_old_model(model, ctx_params);
    }

    void free() {
        llama_free( ctx );
        llama_free_model( model );
    }
};

struct WrappedChatInit
chat_init(const char *model_path) {
    try {
        auto *chat_init = new ChatSession(std::string(model_path));
        return {true, "", chat_init};
    } catch (const std::exception &e) {
        // Catch errors that inherit from std exception
        std::string error_message = e.what();
        // Need to allocate new memory for the error message because the original memory will be freed when this
        const char *error_message_c_str = error_message.c_str();
        char *error_message_c_str_copy = new char[error_message.length() + 1];
        strcpy(error_message_c_str_copy, error_message_c_str);
        return {false, error_message_c_str_copy, {}};
    } catch (...) {
        // Blank catch any other errors if possible
        return {false, "Unknown Error in chat_init(): Could not catch cause of this error", {}};
    }
}

struct WrappedLoadModel load_model(void *chat_session_ptr) {
    try {
        auto *typed_ptr = static_cast<ChatSession *>(chat_session_ptr);
        typed_ptr->load_model();
        return {true, ""};
    } catch (const std::exception &e) {
        // Catch errors that inherit from std exception
        std::string error_message = e.what();
        // Need to allocate new memory for the error message because the original memory will be freed when this
        const char *error_message_c_str = error_message.c_str();
        char *error_message_c_str_copy = new char[error_message.length() + 1];
        strcpy(error_message_c_str_copy, error_message_c_str);
        return {false, error_message_c_str_copy};
    } catch (...) {
        // Blank catch any other errors if possible
        return {false, "Unknown Error in load_model(): Could not catch cause of this error"};
    }
}

struct WrappedChatConverseReturnable
chat_converse(void *chat_session_ptr, const char *input) {
    auto *typed_ptr = static_cast<ChatSession *>(chat_session_ptr);
    WrappedChatConverseReturnable result = typed_ptr->Converse(input);
    return result;
}

struct WrappedChatReset
chat_reset(void *chat_session_ptr) {
    try {
        auto* typed_ptr = static_cast<ChatSession*>(chat_session_ptr);
        typed_ptr->reset();
        return {true, ""};
    } catch (const std::exception& e) {
        // Catch errors that inherit from std exception
        std::string error_message = e.what();
        // Need to allocate new memory for the error message because the original memory will be freed when this
        const char* error_message_c_str = error_message.c_str();
        char* error_message_c_str_copy = new char[error_message.length() + 1];
        strcpy(error_message_c_str_copy, error_message_c_str);
        return {false, error_message_c_str_copy};
    } catch (...) {
        // Blank catch any other errors if possible
        return {false, "Unknown Error in chat_reset(): Could not catch cause of this error"};
    }
}

// Free memory allocated by chat_init
void chat_free(void *chat_session_ptr) {
    auto *typed_ptr = static_cast<ChatSession *>(chat_session_ptr);
    typed_ptr->free();
}
