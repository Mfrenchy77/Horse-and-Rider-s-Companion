(() => {
  const { protocol, hostname } = window.location;
  const isLocal = hostname === 'localhost' || hostname.endsWith('.localhost') ||
    hostname === '127.0.0.1' || hostname === '[::1]';
  // Firebase preview channels use SITE--CHANNEL-HASH.web.app.
  const isHostingPreview = hostname.endsWith('.web.app') && hostname.includes('--');
  if (protocol !== 'https:' || isLocal || isHostingPreview) return;

  const publisher = document.querySelector('meta[name="google-adsense-account"]')?.content;
  if (!publisher) return;

  const script = document.createElement('script');
  script.async = true;
  script.crossOrigin = 'anonymous';
  script.dataset.overlays = 'bottom';
  script.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' +
    encodeURIComponent(publisher);
  document.head.append(script);
})();
