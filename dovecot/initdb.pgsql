CREATE TABLE virtual_domains (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE virtual_users (
    id SERIAL PRIMARY KEY,
    domain_id INTEGER REFERENCES virtual_domains(id) ON DELETE CASCADE,
    password VARCHAR(106) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL
);

CREATE TABLE virtual_aliases (
    id SERIAL PRIMARY KEY,
    domain_id INTEGER REFERENCES virtual_domains(id) ON DELETE CASCADE,
    source VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL
);
