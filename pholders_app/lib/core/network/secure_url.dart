/// Upgrades an `http://` URL the server handed us to `https://`.
///
/// The backend stores absolute URLs built from the scheme it believes it was
/// reached on. Behind a TLS-terminating proxy that reads as `http`, so a
/// stored image URL can say `http://` even though the host only answers over
/// HTTPS. A browser refuses to load such a URL as a subresource of an HTTPS
/// page, and the redirect it would get instead does not rescue it.
///
/// This is defence, not a substitute for the server emitting the right
/// scheme: it rescues rows written before that was fixed, and anything a
/// misconfigured environment writes later.
///
/// Loopback addresses are left alone — plain HTTP is genuinely how a local
/// backend is served, and rewriting it would break development.
String? secureImageUrl(String? url) {
  if (url == null || url.isEmpty) return url;
  const prefix = 'http://';
  if (!url.startsWith(prefix)) return url;

  final rest = url.substring(prefix.length);
  final host = rest.split(RegExp('[:/?#]')).first.toLowerCase();
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') return url;

  return 'https://$rest';
}
