// chat.h
#pragma once

extern "C" {
struct WrappedChatInit {
    bool success;
    const char *error;
    void *data;
};

struct WrappedLoadModel {
    bool success;
    const char *error;
};

struct ChatConverseReturnable {
    const char *output;
};

struct WrappedChatConverseReturnable {
    bool success;
    const char *error;
    ChatConverseReturnable data;
};

struct WrappedChatReset {
    bool success;
    const char *error;
};

struct WrappedChatInit chat_init(const char *model_path);
struct WrappedLoadModel load_model(void *ptr);
struct WrappedChatConverseReturnable chat_converse(void *ptr, const char *input);
struct WrappedChatReset chat_reset(void *ptr);
void chat_free(void *ptr);
}