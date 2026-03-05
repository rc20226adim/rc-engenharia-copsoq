// Export condicional: usa implementação web na web, stub nas outras plataformas
export 'url_helper_stub.dart'
    if (dart.library.js_interop) 'url_helper_web.dart';
