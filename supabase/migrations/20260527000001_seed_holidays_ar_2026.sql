-- Seed Argentine 2026 holidays (feriados) for the day-aware expires_at window.
-- Includes inamovibles, trasladables (already resolved to their effective date),
-- and puentes turísticos no laborables. Sourced from argentinadatos.com/v1/feriados/2026.
--
-- Update yearly: drop a new file `..._seed_holidays_ar_2027.sql` with the next
-- year's list, or hand-edit rows when the executive decrees additional puentes.

insert into holidays (day, name) values
    ('2026-01-01', 'Año Nuevo'),
    ('2026-02-16', 'Carnaval'),
    ('2026-02-17', 'Carnaval'),
    ('2026-03-23', 'Puente turístico no laborable'),
    ('2026-03-24', 'Día Nacional de la Memoria por la Verdad y la Justicia'),
    ('2026-04-02', 'Día del Veterano y de los Caídos en la Guerra de Malvinas'),
    ('2026-04-03', 'Viernes Santo'),
    ('2026-05-01', 'Día del Trabajador'),
    ('2026-05-25', 'Día de la Revolución de Mayo'),
    ('2026-06-15', 'Paso a la Inmortalidad del General Martín Güemes'),
    ('2026-06-20', 'Paso a la Inmortalidad del General Manuel Belgrano'),
    ('2026-07-09', 'Día de la Independencia'),
    ('2026-07-10', 'Puente turístico no laborable'),
    ('2026-08-17', 'Paso a la Inmortalidad del Gral. José de San Martín'),
    ('2026-10-12', 'Día del Respeto a la Diversidad Cultural'),
    ('2026-11-23', 'Día de la Soberanía Nacional'),
    ('2026-12-07', 'Puente turístico no laborable'),
    ('2026-12-08', 'Día de la Inmaculada Concepción de María'),
    ('2026-12-25', 'Navidad')
on conflict (day) do update set name = excluded.name;
