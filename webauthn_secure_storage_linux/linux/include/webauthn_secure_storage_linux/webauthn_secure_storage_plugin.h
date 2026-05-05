#ifndef FLUTTER_PLUGIN_WEBAUTHN_SECURE_STORAGE_PLUGIN_H_
#define FLUTTER_PLUGIN_WEBAUTHN_SECURE_STORAGE_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _WebauthnSecureStoragePlugin WebauthnSecureStoragePlugin;
typedef struct {
  GObjectClass parent_class;
} WebauthnSecureStoragePluginClass;

FLUTTER_PLUGIN_EXPORT GType webauthn_secure_storage_plugin_get_type();

FLUTTER_PLUGIN_EXPORT void webauthn_secure_storage_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif
