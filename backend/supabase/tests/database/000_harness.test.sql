-- Placeholder proving the pgTAP harness runs. Replace once real tests exist.
begin;

select plan(2);

select has_extension('pgtap', 'pgTAP is installed');
select has_schema('public', 'public schema exists');

select * from finish();

rollback;
