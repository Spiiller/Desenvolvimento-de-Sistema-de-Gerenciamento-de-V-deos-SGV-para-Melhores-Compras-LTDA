set serveroutput on;

DECLARE
    CURSOR sac_cursor IS
        SELECT 
            s.nr_sac AS numero_ocorrencia,
            s.dt_abertura_sac AS data_abertura,
            s.hr_abertura_sac AS hora_abertura,
            s.tp_sac AS tipo_sac,
            p.cd_produto AS codigo_produto,
            p.ds_produto AS nome_produto,
            p.vl_unitario AS valor_unitario,
            p.vl_perc_lucro AS percentual_lucro,
            (p.vl_perc_lucro / 100) * p.vl_unitario AS valor_unitario_lucro, -- Calcula o lucro unitário
            c.nr_cliente AS numero_cliente,
            c.nm_cliente AS nome_cliente,
            e.sg_estado AS sg_estado,
            e.nm_estado AS nm_estado
        FROM 
            mc_sgv_sac s
        INNER JOIN 
            mc_produto p ON s.cd_produto = p.cd_produto
        INNER JOIN 
            mc_cliente c ON s.nr_cliente = c.nr_cliente
        INNER JOIN 
            mc_end_cli ec ON c.nr_cliente = ec.nr_cliente
        INNER JOIN 
            mc_logradouro l ON ec.CD_LOGRADOURO_CLI = l.cd_logradouro
        INNER JOIN 
            mc_bairro b ON l.cd_bairro = b.cd_bairro
        INNER JOIN 
            mc_cidade ci ON b.cd_cidade = ci.cd_cidade
        INNER JOIN 
            mc_estado e ON ci.SG_ESTADO = e.SG_ESTADO;

    numero_ocorrencia mc_sgv_sac.nr_sac%TYPE;
    data_abertura mc_sgv_sac.dt_abertura_sac%TYPE;
    hora_abertura mc_sgv_sac.hr_abertura_sac%TYPE;
    tipo_sac mc_sgv_sac.tp_sac%TYPE;
    codigo_produto mc_produto.cd_produto%TYPE;
    nome_produto mc_produto.ds_produto%TYPE;
    valor_unitario mc_produto.vl_unitario%TYPE;
    percentual_lucro mc_produto.vl_perc_lucro%TYPE;
    valor_unitario_lucro NUMBER; -- Lucro unitário sobre o produto
    numero_cliente mc_cliente.nr_cliente%TYPE;
    nome_cliente mc_cliente.nm_cliente%TYPE;
    tipo_classificacao_sac VARCHAR2(20); -- Tipo da coluna DS_TIPO_CLASSIFICACAO_SAC
    sg_estado mc_estado.sg_estado%TYPE;
    nm_estado mc_estado.nm_estado%TYPE;
    vl_icms_produto NUMBER; -- Valor do ICMS do produto
BEGIN
    -- Abre o cursor
    OPEN sac_cursor;

    -- Loop para percorrer os resultados do cursor
    LOOP
        -- Recupera os valores do cursor
        FETCH sac_cursor INTO 
            numero_ocorrencia,
            data_abertura,
            hora_abertura,
            tipo_sac,
            codigo_produto,
            nome_produto,
            valor_unitario, 
            percentual_lucro,
            valor_unitario_lucro,
            numero_cliente,
            nome_cliente,
            sg_estado,
            nm_estado;

        -- Sai do loop se não houver mais linhas a serem recuperadas
        EXIT WHEN sac_cursor%NOTFOUND;

        -- Define a classificação com base no tipo de SAC
        CASE tipo_sac
            WHEN 'S' THEN tipo_classificacao_sac := 'SUGESTÃO';
            WHEN 'D' THEN tipo_classificacao_sac := 'DÚVIDA';
            WHEN 'E' THEN tipo_classificacao_sac := 'ELOGIO';
            ELSE tipo_classificacao_sac := 'CLASSIFICAÇÃO INVÁLIDA';
        END CASE;

        -- Cálculo do ICMS do produto
        SELECT fun_mc_gera_aliquota_media_icms_estado(sg_estado) INTO vl_icms_produto FROM dual;
        
        -- Insira os dados na tabela MC_SGV_OCORRENCIA_SAC
        INSERT INTO MC_SGV_OCORRENCIA_SAC (
            NR_OCORRENCIA_SAC,
            DT_ABERTURA_SAC,
            HR_ABERTURA_SAC,
            CD_PRODUTO,
            DS_PRODUTO,
            VL_UNITARIO_PRODUTO, 
            VL_PERC_LUCRO,
            nr_cliente,
            nm_cliente,
            DS_TIPO_CLASSIFICACAO_SAC,
            SG_ESTADO,
            NM_ESTADO,
            VL_ICMS_PRODUTO
        ) VALUES (
            numero_ocorrencia,
            data_abertura,
            hora_abertura,
            codigo_produto,
            nome_produto,
            valor_unitario, 
            percentual_lucro,
            numero_cliente,
            nome_cliente,
            tipo_classificacao_sac,
            sg_estado,
            nm_estado,
            vl_icms_produto
        );


        -- Faça o que você quiser com os valores recuperados
        -- Por exemplo, exibir na saída
        
        
        DBMS_OUTPUT.PUT_LINE('Número da Ocorrência: ' || numero_ocorrencia ||
                             ', Data de Abertura: ' || data_abertura ||
                             ', Hora de Abertura: ' || hora_abertura ||
                             ', Tipo do SAC: ' || tipo_sac ||
                             ', Classificação do SAC: ' || tipo_classificacao_sac ||
                             ', Código do Produto: ' || codigo_produto ||
                             ', Nome do Produto: ' || nome_produto ||
                             ', Valor Unitário: ' || valor_unitario ||
                             ', Percentual do Lucro: ' || percentual_lucro ||
                             ', Lucro Unitário sobre o Produto: ' || valor_unitario_lucro ||
                             ', Número do Cliente: ' || numero_cliente ||
                             ', Nome do Cliente: ' || nome_cliente ||
                             ', Estado: ' || sg_estado ||
                             ', Nome do Estado: ' || nm_estado ||
                             ', Valor do ICMS do Produto: ' || vl_icms_produto);

    END LOOP;

    -- Fecha o cursor
    CLOSE sac_cursor;
END;
/

Commit;