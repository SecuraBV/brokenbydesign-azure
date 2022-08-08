USE securavulnerabledb
GO
CREATE TABLE vpn_employee_data (
    vpn_username varchar(255),
    vpn_password varchar(255)
)
GO
INSERT INTO vpn_employee_data VALUES ('Employee23187', 'SECURA{VPN_CR3D3NT14LS}')
GO
CREATE LOGIN DevOps WITH PASSWORD = 'SECURA{C0NN3CT10N_STR1NG}';
CREATE USER DevOps FOR LOGIN DevOps;
GO
EXEC sp_addrolemember db_datareader, DevOps;
GO