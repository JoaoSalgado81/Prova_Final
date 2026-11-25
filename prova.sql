CREATE TABLE jogadores (
    id_jogador SERIAL PRIMARY KEY,
    nome_completo VARCHAR(120) NOT NULL,
    nickname VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    status_conta VARCHAR(20) NOT NULL DEFAULT 'ATIVO' CHECK (status_conta IN ('ATIVO', 'INATIVO', 'BANIDO')),
    data_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE modalidades (
    id_modalidade SERIAL PRIMARY KEY,
    nome_jogo VARCHAR(80) NOT NULL UNIQUE,
    categoria VARCHAR(50) NOT NULL CHECK (categoria IN ('FPS', 'MOBA', 'Battle Royale', 'Esportes', 'Luta', 'Estratégia')),
    formato_disputa VARCHAR(30) NOT NULL
);

CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    titulo_confronto VARCHAR(150) NOT NULL,
    data_partida DATE NOT NULL,
    status_disputa VARCHAR(30) NOT NULL DEFAULT 'AGENDADA' CHECK (status_disputa IN ('AGENDADA', 'EM_ANDAMENTO', 'FINALIZADA', 'CANCELADA')),
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_jogador INT NOT NULL REFERENCES jogadores(id_jogador),
    id_modalidade INT NOT NULL REFERENCES modalidades(id_modalidade)
);

CREATE TABLE historico_partidas (
    id_historico SERIAL PRIMARY KEY,
    id_partida INT NOT NULL REFERENCES partidas(id_partida),
    acao_realizada VARCHAR(100) NOT NULL,
    observacao TEXT,
    data_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW vw_painel_principal AS
SELECT 
    j.nickname,
    p.titulo_confronto,
    m.categoria,
    p.data_partida,
    p.status_disputa
FROM partidas p
JOIN jogadores j ON p.id_jogador = j.id_jogador
JOIN modalidades m ON p.id_modalidade = m.id_modalidade;

CREATE VIEW vw_cronograma_partidas AS
SELECT 
    p.titulo_confronto,
    p.data_partida,
    p.status_disputa,
    (p.data_partida - CURRENT_DATE) AS dias_restantes,
    j.nickname
FROM partidas p
JOIN jogadores j ON p.id_jogador = j.id_jogador
ORDER BY p.data_partida ASC;

CREATE FUNCTION fn_buscar_jogadores(termo TEXT)
RETURNS TABLE (
    id_jogador INT,
    nome_completo VARCHAR,
    nickname VARCHAR,
    email VARCHAR,
    status_conta VARCHAR
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id_jogador,
        j.nome_completo,
        j.nickname,
        j.email,
        j.status_conta
    FROM jogadores j
    WHERE j.nickname = termo
       OR j.email = termo;
END;
$$;

CREATE FUNCTION fn_validar_partida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    status_atual VARCHAR(20);
BEGIN
    SELECT status_conta INTO status_atual
    FROM jogadores
    WHERE id_jogador = NEW.id_jogador;

    IF status_atual <> 'ATIVO' THEN
        RAISE EXCEPTION 'Jogador inativo ou banido não pode ser vinculado a partidas.';
    END IF;

    NEW.data_criacao := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE FUNCTION fn_logar_partida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO historico_partidas (id_partida, acao_realizada, observacao)
    VALUES (NEW.id_partida, 'PARTIDA_CRIADA', 'Partida agendada com sucesso.');

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida();

CREATE TRIGGER trg_logar_partida
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_logar_partida();

INSERT INTO jogadores (nome_completo, nickname, email, senha, status_conta) VALUES
('jv', 'FalleN_Jr', 'jv@esports.com', 'senha123', 'ATIVO'),
('Maria', 'MariStrike', 'maria@esports.com', 'mari@2026', 'ATIVO'),
('Rafael', 'RafaSniper', 'rafael@esports.com', 'rafagame99', 'ATIVO'),
('Gabriel', 'ToxicGuy', 'gabriel@esports.com', 'gabe1234', 'BANIDO');

INSERT INTO modalidades (nome_jogo, categoria, formato_disputa) VALUES
('Counter-Strike 2', 'FPS', '5v5'),
('League of Legends', 'MOBA', '5v5'),
('Valorant', 'FPS', '5v5'),
('EA Sports FC 26', 'Esportes', '1v1');

INSERT INTO partidas (titulo_confronto, data_partida, status_disputa, id_jogador, id_modalidade) VALUES
('Quartas de Final - Copa SENAI CS2', CURRENT_DATE + 2, 'AGENDADA', 1, 1),
('Semifinal - Liga Universitária LoL', CURRENT_DATE + 5, 'AGENDADA', 2, 2),
('Grande Final - Desafio Valorant', CURRENT_DATE + 10, 'AGENDADA', 3, 3),
('Abertura - Torneio Relâmpago FC26', CURRENT_DATE + 1, 'AGENDADA', 1, 4);
