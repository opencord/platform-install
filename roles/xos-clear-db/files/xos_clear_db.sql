-- Clear the XOS database (used for testing)

CREATE OR REPLACE FUNCTION truncate_tables(username IN VARCHAR) RETURNS void AS $$
DECLARE
  statements CURSOR FOR
    SELECT tablename FROM pg_tables
    WHERE tableowner = username AND schemaname = 'public';
BEGIN
  FOR stmt IN statements LOOP
    EXECUTE 'TRUNCATE TABLE ' || quote_ident(stmt.tablename) || ' CASCADE;';
  END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT truncate_tables('postgres');

SELECT setval('core_tenant_id_seq', 1);

SELECT setval('core_deployment_id_seq', 1);

SELECT setval('core_flavor_id_seq', 1);

SELECT setval('core_service_id_seq', 1);

