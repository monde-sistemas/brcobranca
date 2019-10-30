# -*- encoding: utf-8 -*-

module Brcobranca
  module Remessa
    module Cnab400
      class Credisis < Brcobranca::Remessa::Cnab400::Base
        ESPECIES_TITULOS = {
          'DMI' => '03',
          'DSI' => '05',
          'NP' => '12',
          'RC' => '17',
          'ME' => '21',
          'NF' => '23'
        }.freeze

        CODIGOS_MULTA = {
          '0' => 'I',
          '1' => 'F',
          '2' => 'P'
        }.freeze

        CODIGOS_MORA = {
          '3' => 'I',
          '1' => 'F',
          '2' => 'P'
        }.freeze

        CODIGOS_DESCONTO = {
          '0' => 'I',
          '1' => 'F',
          '2' => 'P'
        }.freeze

        attr_accessor :nome_cedente
        attr_accessor :documento_cedente
        attr_accessor :logradouro_cedente
        attr_accessor :numero_cedente
        attr_accessor :complemento_cedente
        attr_accessor :bairro_cedente
        attr_accessor :cidade_cedente
        attr_accessor :uf_cedente
        attr_accessor :cep_cedente
        attr_accessor :convenio
        attr_accessor :parcela
        attr_accessor :codigo_cedente

        validates_presence_of :agencia, :conta_corrente, :digito_conta, :parcela,
                              :convenio, :sequencial_remessa, :documento_cedente, :nome_cedente,
                              :logradouro_cedente, :numero_cedente, :bairro_cedente, :cidade_cedente,
                              :uf_cedente, :cep_cedente
        validates_length_of :convenio, maximum: 6
        validates_length_of :agencia, maximum: 4
        validates_length_of :conta_corrente, maximum: 8
        validates_length_of :carteira, maximum: 2
        validates_length_of :digito_conta, maximum: 1
        validates_length_of :sequencial_remessa, maximum: 7

        # Nova instancia do CrediSIS
        def initialize(campos = {})
          campos = {
            aceite: 'N',
            parcela: '01'
          }.merge!(campos)
          super(campos)
        end

        def agencia=(valor)
          @agencia = valor.to_s.rjust(4, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(8, '0') if valor
        end

        def carteira=(valor)
          @carteira = valor.to_s.rjust(2, '0') if valor
        end

        def pagamentos=(valor)
          @pagamentos = (valor || []).map do |pagamento|
            pagamento[:validar_numero_sacado] = true
            pagamento
          end
        end

        def cod_banco
          '097'
        end

        def nome_banco
          'CENTRALCREDI'.ljust(15, ' ')
        end

        # Informacoes da conta corrente do cedente
        #
        # @return [String]
        #
        def info_conta
          # CAMPO                    TAMANHO
          # agencia                  4
          # complemento              1
          # conta corrente           8
          # digito da conta          1
          # complemento              6
          "#{agencia} #{conta_corrente}#{digito_conta}#{''.rjust(6, ' ')}"
        end

        # Complemento do header
        #
        # @return [String]
        #
        def complemento
          brancos = ' ' * 284
          versao_arquivo = '001'
          "#{sequencial_remessa.to_s.rjust(7, '0')}#{brancos}#{versao_arquivo}"
        end

        # Detalhe do arquivo
        #
        # @param pagamento [PagamentoCnab400]
        #   objeto contendo as informacoes referentes ao boleto (valor, vencimento, cliente)
        # @param sequencial
        #   num. sequencial do registro no arquivo
        #
        # @return [String]
        #
        def monta_detalhe(pagamento, sequencial)
          fail Brcobranca::RemessaInvalida.new(pagamento) if pagamento.invalid?

          detalhe = '1'                                                     # identificacao transacao               9[01]
          detalhe << tipo_identificacao_cedente                             # tipo de identificacao da empresa      9[02]
          detalhe << documento_cedente.to_s.rjust(14, '0')     # cpf/cnpj da empresa                   9[14]
          detalhe << agencia                                                # agencia                               9[04]
          detalhe << conta_corrente.rjust(8, '0')                           # conta corrente                        9[08]
          detalhe << digito_conta                                           # dac                                   9[01]
          detalhe << ' ' * 26                                               # brancos                               X[26]
          detalhe << formata_nosso_numero(pagamento.nosso_numero.to_s)      # nosso numero                          9[20]
          detalhe << codigo_operacao                                        # codigo da operação                    9[02]
          detalhe << data_geracao                                           # data da operacao                      D[06]
          detalhe << ' ' * 6                                                # brancos                               X[06]
          detalhe << parcela.rjust(2, '0')                                  # parcela                               9[02]
          detalhe << tipo_pagamento                                         # tipo pagamento                        9[01]
          detalhe << tipo_recebimento                                       # tipo recebimento                      9[01]
          detalhe << especie_titulo(pagamento)                              # especie titulo                        9[01]
          detalhe << tipo_dias_protesto                                     # tipo dias protesto                    9[01]
          detalhe << pagamento.dias_protesto.rjust(2, '0')                  # dias protesto                         9[02]
          detalhe << tipo_protesto                                          # tipo de envio do protesto             X[02]
          detalhe << ' ' * 9                                                # brancos                               X[09]
          detalhe << pagamento.documento_ou_numero.to_s.ljust(10)    # numero do documento                   A[10]
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')           # data do vencimento                    D[06]
          detalhe << pagamento.formata_valor                                # valor do documento                    V[13]
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')           # data limite para recimento            D[06]
          detalhe << ' ' * 5                                                # brancos                               X[05]
          detalhe << pagamento.data_emissao.strftime('%d%m%y')              # data da emissao                       D[06]
          detalhe << ' '                                                    # brancos                               X[01]
          detalhe << pagamento.identificacao_sacado                         # identificacao do pagador              9[02]
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0') # documento do pagador                  9[14]
          detalhe << pagamento.nome_sacado.format_size(40)                  # nome do pagador                       A[40]
          detalhe << ' ' * 25                                               # nome fantasia do pagador              A[25]
          detalhe << pagamento.logradouro_sacado.format_size(35)            # logradouro                            A[35]
          detalhe << pagamento.numero_sacado.format_size(6)                 # numero endereco do pagador            9[06]
          detalhe << pagamento.bairro_sacado.format_size(25)                # bairro do pagador                     X[25]
          detalhe << pagamento.cidade_sacado.format_size(25)                # cidade do pagador                     A[25]
          detalhe << pagamento.uf_sacado                                    # uf do pagador                         A[02]
          detalhe << pagamento.cep_sacado                                   # cep do pagador                        9[08]
          detalhe << ' ' * 11                                               # telefone do pagador                   9[11]
          detalhe << ' ' * 43                                               # email do pagador                      A[43]
          detalhe << ' '                                                    # brancos                               X[01]
          detalhe << sequencial.to_s.rjust(6, '0')             # numero do registro no arquivo         9[06]
          detalhe
        end

        def monta_detalhe_opcional(pagamento, sequencial)
          detalhe = '2'                                                     # identificacao # transacao             9[01]
          detalhe << tipo_identificacao_cedente                             # tipo de identificacao da empresa      9[02]
          detalhe << documento_cedente.to_s.rjust(14, '0')     # cpf/cnpj da empresa                   9[14
          detalhe << nome_cedente.format_size(40)                           # nome do sacador/avalista              A[40]
          detalhe << logradouro_cedente.format_size(35)                     # logradouro do sacador/avalista        A[35]
          detalhe << numero_cedente.format_size(6)                          # numero do sacador/avalista            9[6]
          detalhe << complemento_cedente.format_size(25)                    # complemento do sacador/avalista       A[25]
          detalhe << bairro_cedente.format_size(25)                         # bairro do sacador/avalista            A[35]
          detalhe << cidade_cedente.format_size(25)                         # cidade do sacador/avalista            A[25]
          detalhe << uf_cedente.format_size(2)                              # uf do sacador/avalista                A[02]
          detalhe << cep_cedente.format_size(8)                             # uf do sacador/avalista                A[02]
          detalhe << ' '                                                    # brancos                               X[01]
          detalhe << pagamento.instrucoes_boleto.format_size(99)            # instrucoes                            A[100]
          detalhe << ' '                                                    # brancos                               X[01]
          detalhe << pagamento.formata_valor_mora(15)                       # valor juros                           V[15]
          detalhe << CODIGOS_MORA[pagamento.codigo_mora]                    # codigo tipo da mora                   A[01]
          detalhe << '2'                                                    # tipo carência do juros                9[01]
          detalhe << '00'                                                   # dias carência do juros                9[01]
          detalhe << pagamento.formata_percentual_multa(15)                 # valor multa                           V[15]
          detalhe << CODIGOS_MULTA[pagamento.codigo_multa]                  # codigo tipo da multa                  A[01]
          detalhe << '2'                                                    # tipo carência do multa                9[01]
          detalhe << '00'                                                   # dias carência da multa                9[02]
          detalhe << pagamento.formata_data_desconto                        # data primeiro desconto                D[06]
          detalhe << pagamento.formata_valor_desconto(13)                   # valor primeiro desconto               V[13]
          detalhe << CODIGOS_DESCONTO[pagamento.cod_desconto]               # codigo primeiro desconto              A[01]
          detalhe << pagamento.formata_data_segundo_desconto                # data segundo desconto                 D[06]
          detalhe << pagamento.formata_valor_segundo_desconto(13)           # valor segundo desconto                V[13]
          detalhe << CODIGOS_DESCONTO[pagamento.cod_segundo_desconto]       # codigo segundo desconto               A[01]
          detalhe << pagamento.formata_data_terceiro_desconto               # data terceiro desconto                D[06]
          detalhe << pagamento.formata_valor_terceiro_desconto(13)          # valor terceiro desconto               V[13]
          detalhe << CODIGOS_DESCONTO[pagamento.cod_terceiro_desconto]      # codigo terceiro desconto              A[01]
          detalhe << ' ' * 12                                               # brancos                               X[12]
          detalhe << sequencial.to_s.rjust(6, '0')             # numero do registro no arquivo         9[06]
          detalhe
        end

        def formata_nosso_numero(nosso_numero)
          # 0 9 7 X A A A A C C C C C C S S S S S S
          #
          # X – Módulo 11 do CPF/CNPJ (incluindo dígitos verificadores) do Beneficiário.
          # A – Código da Agência CrediSIS ao qual o Beneficiário possui Conta
          # C – Código de Convênio do Beneficiário no Sistema CrediSIS
          # S – Sequencial Único do Boleto
          "#{cod_banco}#{documento_cedente_dv}#{agencia.rjust(4, '0')}#{convenio.rjust(6, '0')}#{nosso_numero.rjust(6, '0')}"
        end

        def codigo_operacao
          # Inclusão de título 01
          # Baixa manual 02
          # Cancelamento 03
          # Alteração dos Dados 04
          '01'
        end

        def especie_titulo_padrao
          '02'
        end

        def tipo_pagamento
          # Valor padrão: 3 – Nao aceitar pagamento com o valor divergente
          '3'
        end

        def tipo_recebimento
          # Valor fixo: 3 – Nao receber valor divergente do informado
          '3'
        end

        def tipo_protesto
          # 01- Cartório
          # 02 – Serasa
          # 03 - Nenhum
          '03'
        end

        def tipo_dias_protesto
          # 1- Úteis
          # 2 - Corridos
          '2'
        end

        def tipo_identificacao_cedente
          Brcobranca::Util::Empresa.new(documento_cedente).tipo
        end

        def documento_cedente_dv
          documento_cedente.modulo11(mapeamento: Boleto::Credisis::MAPEAMENTO_MODULO11)
        end

        def gera_detalhe_multa?(pagamento)
          !pagamento.instrucoes_boleto.blank?
        end
      end
    end
  end
end
