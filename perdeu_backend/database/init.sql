-- Habilita a extensão para geração de UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Criação da tabela de utilizadores
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    matricula VARCHAR UNIQUE NOT NULL,
    senha_hash VARCHAR NOT NULL,
    nome_completo VARCHAR NOT NULL,
    email_institucional VARCHAR UNIQUE NOT NULL,
    perfil VARCHAR NOT NULL CHECK (perfil IN ('ADMIN', 'PROFESSOR', 'ALUNO')),
    status_ativo BOOLEAN DEFAULT TRUE,
    primeiro_acesso BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir um Admin de teste (A senha hash aqui é um SHA-256 fictício para 'perdeuunicatolica')
-- NOTA: O hash real de 'perdeuunicatolica' em SHA256 é:
-- 62c64b581232814cdcfb964f4340d82de2600234ea720515e06dc72c05763071
INSERT INTO usuarios (matricula, senha_hash, nome_completo, email_institucional, perfil)
VALUES ('admin123', '62c64b581232814cdcfb964f4340d82de2600234ea720515e06dc72c05763071', 'Administrador Sistema', 'admin@unicatolica.edu.br', 'ADMIN');