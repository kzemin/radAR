-- Starter RSS feed list for the ingest-news function. Run in the SQL editor.
-- VERIFY each URL before relying on it — Argentine outlets change RSS paths and
-- several use Arc Publishing feeds. Add/drop rows freely; the function reads this
-- table at runtime (no redeploy needed). Tier: 1 wire … 4 aggregator.
insert into sources (id, name, url, tier, kind) values
  ('infobae',   'Infobae',            'https://www.infobae.com/feeds/rss/',                         2, 'rss'),
  ('lanacion',  'La Nación',          'https://www.lanacion.com.ar/arc/outboundfeeds/rss/',         2, 'rss'),
  ('clarin',    'Clarín',             'https://www.clarin.com/rss/lo-ultimo/',                      2, 'rss'),
  ('pagina12',  'Página/12',          'https://www.pagina12.com.ar/rss/portada',                    3, 'rss'),
  ('ambito',    'Ámbito Financiero',  'https://www.ambito.com/rss/pages/home.xml',                  3, 'rss'),
  ('tn',        'Todo Noticias',      'https://tn.com.ar/feed/',                                    3, 'rss'),
  ('lavoz',     'La Voz (Córdoba)',   'https://www.lavoz.com.ar/arc/outboundfeeds/rss/',            3, 'rss'),
  ('losandes',  'Los Andes (Mendoza)', 'https://www.losandes.com.ar/arc/outboundfeeds/rss/',        3, 'rss'),
  ('rionegro',  'Río Negro',          'https://www.rionegro.com.ar/feed/',                          3, 'rss'),
  ('ole',       'Olé (deportes)',     'https://www.ole.com.ar/rss/ultimas-noticias/',               3, 'rss')
on conflict (id) do update set
  name = excluded.name, url = excluded.url, tier = excluded.tier, kind = excluded.kind;
