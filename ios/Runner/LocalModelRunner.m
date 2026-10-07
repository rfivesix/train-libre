// ios/Runner/LocalModelRunner.m

#import "LocalModelRunner.h"
#import "LlamaHeaders/llama.h"
#import "LlamaHeaders/mtmd.h"
#import "LlamaHeaders/mtmd-helper.h"
#import <dlfcn.h>

typedef struct {
    void * handle;
    void (*llama_backend_init)(void);
    void (*llama_backend_free)(void);
    struct llama_model_params (*llama_model_default_params)(void);
    struct llama_model * (*llama_model_load_from_file)(const char *, struct llama_model_params);
    void (*llama_model_free)(struct llama_model *);
    const struct llama_vocab * (*llama_model_get_vocab)(const struct llama_model *);
    struct llama_context_params (*llama_context_default_params)(void);
    struct llama_context * (*llama_init_from_model)(struct llama_model *, struct llama_context_params);
    void (*llama_free)(struct llama_context *);
    struct llama_batch (*llama_batch_init)(int32_t, int32_t, int32_t);
    void (*llama_batch_free)(struct llama_batch);
    int32_t (*llama_decode)(struct llama_context *, struct llama_batch);
    int32_t (*llama_tokenize)(const struct llama_vocab *, const char *, int32_t, llama_token *, int32_t, bool, bool);
    struct llama_sampler_chain_params (*llama_sampler_chain_default_params)(void);
    struct llama_sampler * (*llama_sampler_chain_init)(struct llama_sampler_chain_params);
    void (*llama_sampler_chain_add)(struct llama_sampler *, struct llama_sampler *);
    struct llama_sampler * (*llama_sampler_init_temp)(float);
    struct llama_sampler * (*llama_sampler_init_dist)(uint32_t);
    llama_token (*llama_sampler_sample)(struct llama_sampler *, struct llama_context *, int32_t);
    void (*llama_sampler_free)(struct llama_sampler *);
    bool (*llama_vocab_is_eog)(const struct llama_vocab *, llama_token);
    int32_t (*llama_token_to_piece)(const struct llama_vocab *, llama_token, char *, int32_t, int32_t, bool);
    
    // Multimodal (mtmd)
    struct mtmd_context_params (*mtmd_context_params_default)(void);
    struct mtmd_context * (*mtmd_init_from_file)(const char *, const struct llama_model *, const struct mtmd_context_params);
    void (*mtmd_free)(struct mtmd_context *);
    void (*mtmd_bitmap_free)(struct mtmd_bitmap *);
    struct mtmd_helper_init_opt (*mtmd_helper_init_opt_default)(void);
    struct mtmd_helper_bitmap_wrapper (*mtmd_helper_bitmap_init_from_buf)(const struct mtmd_context *, const unsigned char *, size_t, bool, struct mtmd_helper_init_opt);
    struct mtmd_input_chunks * (*mtmd_input_chunks_init)(void);
    void (*mtmd_input_chunks_free)(struct mtmd_input_chunks *);
    int32_t (*mtmd_tokenize)(const struct mtmd_context *, struct mtmd_input_chunks *, const struct mtmd_input_text *, const struct mtmd_bitmap * const *, size_t);
    int32_t (*mtmd_helper_eval_chunks)(struct mtmd_context *, struct llama_context *, const struct mtmd_input_chunks *, llama_pos, llama_seq_id, int32_t, bool, llama_pos *);
    const char * (*mtmd_default_marker)(void);
} LlamaAPI;

static void * get_llama_handle(void) {
    static void * s_handle = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString * privPath = [NSBundle.mainBundle.privateFrameworksPath stringByAppendingPathComponent:@"llama.framework/llama"];
        NSString * bundleFwPath = [[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"Frameworks"] stringByAppendingPathComponent:@"llama.framework/llama"];
        NSArray<NSString *> * candidates = @[
            privPath,
            bundleFwPath,
            @"llama.framework/llama"
        ];
        for (NSString * path in candidates) {
            void * h = dlopen(path.UTF8String, RTLD_NOW | RTLD_LOCAL);
            if (h) {
                s_handle = h;
                NSLog(@"[LocalModelRunner] Successfully loaded llama.framework from %@", path);
                break;
            }
        }
        if (!s_handle) {
            void * h = dlopen(NULL, RTLD_NOW);
            if (h && dlsym(h, "llama_backend_init")) {
                s_handle = h;
                NSLog(@"[LocalModelRunner] Successfully linked global llama symbols");
            }
        }
    });
    return s_handle;
}

static BOOL load_api(LlamaAPI * api, void * handle) {
    if (!handle) return NO;
    api->handle = handle;
    #define LOAD_SYM(name) api->name = (__typeof__(api->name))dlsym(handle, #name); if (!api->name) { NSLog(@"[LocalModelRunner] Missing symbol: %s", #name); return NO; }
    LOAD_SYM(llama_backend_init);
    LOAD_SYM(llama_backend_free);
    LOAD_SYM(llama_model_default_params);
    LOAD_SYM(llama_model_load_from_file);
    LOAD_SYM(llama_model_free);
    LOAD_SYM(llama_model_get_vocab);
    LOAD_SYM(llama_context_default_params);
    LOAD_SYM(llama_init_from_model);
    LOAD_SYM(llama_free);
    LOAD_SYM(llama_batch_init);
    LOAD_SYM(llama_batch_free);
    LOAD_SYM(llama_decode);
    LOAD_SYM(llama_tokenize);
    LOAD_SYM(llama_sampler_chain_default_params);
    LOAD_SYM(llama_sampler_chain_init);
    LOAD_SYM(llama_sampler_chain_add);
    LOAD_SYM(llama_sampler_init_temp);
    LOAD_SYM(llama_sampler_init_dist);
    LOAD_SYM(llama_sampler_sample);
    LOAD_SYM(llama_sampler_free);
    LOAD_SYM(llama_vocab_is_eog);
    LOAD_SYM(llama_token_to_piece);
    LOAD_SYM(mtmd_context_params_default);
    LOAD_SYM(mtmd_init_from_file);
    LOAD_SYM(mtmd_free);
    LOAD_SYM(mtmd_bitmap_free);
    LOAD_SYM(mtmd_helper_init_opt_default);
    LOAD_SYM(mtmd_helper_bitmap_init_from_buf);
    LOAD_SYM(mtmd_input_chunks_init);
    LOAD_SYM(mtmd_input_chunks_free);
    LOAD_SYM(mtmd_tokenize);
    LOAD_SYM(mtmd_helper_eval_chunks);
    LOAD_SYM(mtmd_default_marker);
    #undef LOAD_SYM
    return YES;
}

@implementation LocalModelRunner

+ (BOOL)isAvailable {
    return get_llama_handle() != NULL;
}

+ (nullable NSString *)runInferenceWithModelPath:(NSString *)modelPath
                                     mmprojPath:(nullable NSString *)mmprojPath
                                         prompt:(NSString *)prompt
                                   imagesBase64:(NSArray<NSString *> *)imagesBase64
                                          error:(NSError * _Nullable * _Nullable)error {
    void * handle = get_llama_handle();
    if (!handle) {
        if (error) {
            *error = [NSError errorWithDomain:@"LocalModelRunner"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Die native On-Device Engine (llama.framework) ist auf diesem Gerät noch nicht verfügbar."}];
        }
        return nil;
    }

    LlamaAPI api = {0};
    if (!load_api(&api, handle)) {
        if (error) {
            *error = [NSError errorWithDomain:@"LocalModelRunner"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"Die Schnittstellen der Metal-Engine konnten nicht initialisiert werden."}];
        }
        return nil;
    }

    api.llama_backend_init();

    // 1. Model Laden (mit Metal GPU Offload)
    struct llama_model_params mparams = api.llama_model_default_params();
    mparams.n_gpu_layers = 99; // Volle Metal GPU Beschleunigung auf Apple Silicon
    struct llama_model * model = api.llama_model_load_from_file(modelPath.UTF8String, mparams);
    if (!model) {
        api.llama_backend_free();
        if (error) {
            *error = [NSError errorWithDomain:@"LocalModelRunner"
                                         code:1003
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"GGUF-Modell konnte nicht geladen werden: %@", modelPath.lastPathComponent]}];
        }
        return nil;
    }

    // 2. Kontext Initialisieren
    int n_threads = (int)MAX(1, MIN(6, NSProcessInfo.processInfo.processorCount - 2));
    struct llama_context_params cparams = api.llama_context_default_params();
    cparams.n_ctx = 2048;
    cparams.n_threads = n_threads;
    cparams.n_threads_batch = n_threads;

    struct llama_context * lctx = api.llama_init_from_model(model, cparams);
    if (!lctx) {
        api.llama_model_free(model);
        api.llama_backend_free();
        if (error) {
            *error = [NSError errorWithDomain:@"LocalModelRunner"
                                         code:1004
                                     userInfo:@{NSLocalizedDescriptionKey: @"Kontext für On-Device Modell konnte nicht erzeugt werden."}];
        }
        return nil;
    }

    // 3. Sampler Kette
    struct llama_sampler_chain_params sparams = api.llama_sampler_chain_default_params();
    struct llama_sampler * smpl = api.llama_sampler_chain_init(sparams);
    api.llama_sampler_chain_add(smpl, api.llama_sampler_init_temp(0.3f));
    api.llama_sampler_chain_add(smpl, api.llama_sampler_init_dist(1234));
    const struct llama_vocab * vocab = api.llama_model_get_vocab(model);

    llama_pos n_past = 0;
    BOOL hasImages = (imagesBase64.count > 0 && mmprojPath.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:mmprojPath]);

    if (hasImages) {
        // --- Multimodaler Vision-Pfad ---
        struct mtmd_context_params mtmd_params = api.mtmd_context_params_default();
        mtmd_params.use_gpu = true;
        mtmd_params.n_threads = n_threads;
        struct mtmd_context * ctx_vision = api.mtmd_init_from_file(mmprojPath.UTF8String, model, mtmd_params);
        if (!ctx_vision) {
            api.llama_sampler_free(smpl);
            api.llama_free(lctx);
            api.llama_model_free(model);
            api.llama_backend_free();
            if (error) {
                *error = [NSError errorWithDomain:@"LocalModelRunner"
                                             code:1005
                                         userInfo:@{NSLocalizedDescriptionKey: @"Vision-Projektor (mmproj) konnte nicht initialisiert werden."}];
            }
            return nil;
        }

        // Bitmaps erzeugen
        struct mtmd_helper_init_opt opt = api.mtmd_helper_init_opt_default();
        NSMutableArray * rawBitmaps = [NSMutableArray array];
        for (NSString * b64 in imagesBase64) {
            NSData * imgData = [[NSData alloc] initWithBase64EncodedString:b64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
            if (!imgData || imgData.length == 0) continue;
            struct mtmd_helper_bitmap_wrapper wrapper = api.mtmd_helper_bitmap_init_from_buf(ctx_vision, (const unsigned char *)imgData.bytes, imgData.length, false, opt);
            if (wrapper.bitmap) {
                [rawBitmaps addObject:[NSValue valueWithPointer:wrapper.bitmap]];
            }
        }

        const char * marker = api.mtmd_default_marker();
        NSMutableString * fullPrompt = [NSMutableString string];
        for (NSUInteger i = 0; i < rawBitmaps.count; i++) {
            [fullPrompt appendFormat:@"%s\n", marker];
        }
        [fullPrompt appendString:prompt];

        struct mtmd_input_text text_input;
        text_input.text = fullPrompt.UTF8String;
        text_input.text_len = strlen(text_input.text);
        text_input.add_special = true;
        text_input.parse_special = true;

        struct mtmd_bitmap ** bitmapsArray = malloc(sizeof(struct mtmd_bitmap *) * rawBitmaps.count);
        for (NSUInteger i = 0; i < rawBitmaps.count; i++) {
            bitmapsArray[i] = (struct mtmd_bitmap *)[rawBitmaps[i] pointerValue];
        }

        struct mtmd_input_chunks * chunks = api.mtmd_input_chunks_init();
        int32_t tok_res = api.mtmd_tokenize(ctx_vision, chunks, &text_input, (const struct mtmd_bitmap * const *)bitmapsArray, rawBitmaps.count);
        if (tok_res != 0) {
            for (NSUInteger i = 0; i < rawBitmaps.count; i++) api.mtmd_bitmap_free(bitmapsArray[i]);
            free(bitmapsArray);
            api.mtmd_input_chunks_free(chunks);
            api.mtmd_free(ctx_vision);
            api.llama_sampler_free(smpl);
            api.llama_free(lctx);
            api.llama_model_free(model);
            api.llama_backend_free();
            if (error) {
                *error = [NSError errorWithDomain:@"LocalModelRunner"
                                             code:1006
                                         userInfo:@{NSLocalizedDescriptionKey: @"Multimodale Tokenisierung fehlgeschlagen."}];
            }
            return nil;
        }

        llama_pos new_n_past = 0;
        int32_t eval_res = api.mtmd_helper_eval_chunks(ctx_vision, lctx, chunks, n_past, 0, 512, true, &new_n_past);
        for (NSUInteger i = 0; i < rawBitmaps.count; i++) api.mtmd_bitmap_free(bitmapsArray[i]);
        free(bitmapsArray);
        api.mtmd_input_chunks_free(chunks);
        api.mtmd_free(ctx_vision);

        if (eval_res != 0) {
            api.llama_sampler_free(smpl);
            api.llama_free(lctx);
            api.llama_model_free(model);
            api.llama_backend_free();
            if (error) {
                *error = [NSError errorWithDomain:@"LocalModelRunner"
                                             code:1007
                                         userInfo:@{NSLocalizedDescriptionKey: @"Multimodale Bildverarbeitung fehlgeschlagen."}];
            }
            return nil;
        }
        n_past = new_n_past;
    } else {
        // --- Text-Only Pfad (z.B. Verbindungstest) ---
        int32_t n_tokens_max = (int32_t)prompt.length + 512;
        llama_token * tokens = malloc(sizeof(llama_token) * n_tokens_max);
        int32_t n_tokens = api.llama_tokenize(vocab, prompt.UTF8String, (int32_t)strlen(prompt.UTF8String), tokens, n_tokens_max, true, true);
        if (n_tokens < 0) {
            n_tokens_max = -n_tokens;
            tokens = realloc(tokens, sizeof(llama_token) * n_tokens_max);
            n_tokens = api.llama_tokenize(vocab, prompt.UTF8String, (int32_t)strlen(prompt.UTF8String), tokens, n_tokens_max, true, true);
        }

        if (n_tokens > 0) {
            struct llama_batch batch = api.llama_batch_init(MAX(512, n_tokens), 0, 1);
            for (int32_t i = 0; i < n_tokens; i++) {
                batch.token[i] = tokens[i];
                batch.pos[i] = i;
                batch.n_seq_id[i] = 1;
                batch.seq_id[i][0] = 0;
                batch.logits[i] = (i == n_tokens - 1) ? 1 : 0;
            }
            batch.n_tokens = n_tokens;
            if (api.llama_decode(lctx, batch) != 0) {
                api.llama_batch_free(batch);
                free(tokens);
                api.llama_sampler_free(smpl);
                api.llama_free(lctx);
                api.llama_model_free(model);
                api.llama_backend_free();
                if (error) {
                    *error = [NSError errorWithDomain:@"LocalModelRunner"
                                                 code:1008
                                             userInfo:@{NSLocalizedDescriptionKey: @"Text-Evaluation fehlgeschlagen."}];
                }
                return nil;
            }
            api.llama_batch_free(batch);
            n_past = n_tokens;
        }
        free(tokens);
    }

    // 4. Token-Generierungs-Schleife
    NSMutableString * generatedText = [NSMutableString string];
    const int max_tokens = 1024;
    struct llama_batch gen_batch = api.llama_batch_init(1, 0, 1);

    for (int i = 0; i < max_tokens; i++) {
        llama_token token = api.llama_sampler_sample(smpl, lctx, -1);
        if (api.llama_vocab_is_eog(vocab, token)) {
            break;
        }

        char piece_buf[256] = {0};
        int32_t n_piece = api.llama_token_to_piece(vocab, token, piece_buf, sizeof(piece_buf), 0, true);
        if (n_piece > 0) {
            NSString * piece = [[NSString alloc] initWithBytes:piece_buf length:n_piece encoding:NSUTF8StringEncoding];
            if (piece) {
                [generatedText appendString:piece];
            }
        }

        gen_batch.token[0] = token;
        gen_batch.pos[0] = n_past;
        gen_batch.n_seq_id[0] = 1;
        gen_batch.seq_id[0][0] = 0;
        gen_batch.logits[0] = 1;
        gen_batch.n_tokens = 1;
        n_past++;

        if (api.llama_decode(lctx, gen_batch) != 0) {
            break;
        }
    }

    api.llama_batch_free(gen_batch);
    api.llama_sampler_free(smpl);
    api.llama_free(lctx);
    api.llama_model_free(model);
    api.llama_backend_free();

    return [generatedText copy];
}

@end
