USE securavulnerabledb
GO
CREATE TABLE secura_flags (
    flag varchar(255),
    description varchar(255)
)
GO
INSERT INTO secura_flags VALUES ('SECURA{PWN3D_D4T4B4S3}', 'Submit the flag on the website!')
INSERT INTO secura_flags VALUES ('SECURA{PWN3D_D4T4B4S3}', 'Submit the flag on the website!')
INSERT INTO secura_flags VALUES ('SECURA{PWN3D_D4T4B4S3}', 'Submit the flag on the website!')
INSERT INTO secura_flags VALUES ('SECURA{PWN3D_D4T4B4S3}', 'Submit the flag on the website!')
GO
CREATE LOGIN DevOps WITH PASSWORD = 'SECURA{C0NN3CT10N_STR1NG}';
CREATE USER DevOps FOR LOGIN DevOps;
GO
EXEC sp_addrolemember db_datareader, DevOps;
GO