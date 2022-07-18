CREATE LOGIN DevOps WITH PASSWORD = 'SECURA{C0NN3CT10N_STR1NG}';
CREATE USER DevOps FOR LOGIN DevOps;
GO
-- Give rolls to user in sql_setup.sql because we can't do this in the 'master' database