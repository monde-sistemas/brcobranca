# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab400
      class Itau < Brcobranca::Remessa::Cnab400::Base
        VALOR_EM_REAIS = '1'.freeze
        VALOR_EM_PERCENTUAL = '2'.freeze
        ESPECIES_TITULOS = {
          'DM' => '01',
          'NP' => '02',
          'NS' => '03',
          'ME' => '04',
          'RC' => '05',
          'CT' => '06',
          'CS' => '07',
          'DS' => '08',
          'DSI' => '08',
          'LC' => '09',
          'ND' => '13',
          'DV' => '15',
          'EC' => '16',
          'CP' => '17',
          'BP' => '18',
          'OU' => '99'
        }.freeze

        # documento do cedente
        attr_accessor :documento_cedente

        validates_presence_of :agencia, :conta_corrente, :documento_cedente, :digito_conta
        validates_length_of :agencia, maximum: 4
        validates_length_of :conta_corrente, maximum: 5
        validates_length_of :documento_cedente, in: 11..14
        validates_length_of :carteira, maximum: 3
        validates_length_of :digito_conta, maximum: 1

        # Nova instancia do Itau
        def initialize(campos = {})
          campos = { aceite: 'N' }.merge!(campos)
          super(campos)
        end

        def agencia=(valor)
          @agencia = valor.to_s.rjust(4, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(5, '0') if valor
        end

        def carteira=(valor)
          @carteira = valor.to_s.rjust(3, '0') if valor
        end

        def especie_titulo_padrao
          '99'
        end

        def cod_banco
          '341'
        end

        def nome_banco
          'BANCO ITAU SA'.ljust(15, ' ')
        end

        # Informacoes da conta corrente do cedente
        #
        # @return [String]
        #
        def info_conta
          # CAMPO            TAMANHO
          # agencia          4
          # complemento      2
          # conta corrente   5
          # digito da conta  1
          # complemento      8
          "#{agencia}00#{conta_corrente}#{digito_conta}#{''.rjust(8, ' ')}"
        end

        # Complemento do header
        # (no caso do Itau, sao apenas espacos em branco)
        #
        # @return [String]
        #
        def complemento
          ''.rjust(294, ' ')
        end

        # Codigo da carteira de acordo com a documentacao o Itau
        # se a carteira nao forem as testadas (150, 191 e 147)
        # retorna 'I' que é o codigo das carteiras restantes na documentacao
        #
        # @return [String]
        #
        def codigo_carteira
          return 'U' if carteira.to_s == '150'
          return '1' if carteira.to_s == '191'
          return 'E' if carteira.to_s == '147'
          'I'
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
          detalhe << Brcobranca::Util::Empresa.new(documento_cedente).tipo  # tipo de identificacao da empresa      9[02]
          detalhe << documento_cedente.to_s.rjust(14, '0')                  # cpf/cnpj da empresa                   9[14]
          detalhe << agencia                                                # agencia                               9[04]
          detalhe << ''.rjust(2, '0')                                       # complemento de registro (zeros)       9[02]
          detalhe << conta_corrente                                         # conta corrente                        9[05]
          detalhe << digito_conta                                           # dac                                   9[01]
          detalhe << ''.rjust(4, ' ')                                       # complemento do registro (brancos)     X[04]
          detalhe << ''.rjust(4, '0')                                       # codigo cancelamento (zeros)           9[04]
          detalhe << pagamento.documento_ou_numero.to_s.ljust(25)           # identificacao do tit. na empresa      X[25]
          detalhe << pagamento.nosso_numero.to_s.rjust(8, '0')              # nosso numero                          9[08]
          detalhe << ''.rjust(13, '0')                                      # quantidade de moeda variavel          9[13]
          detalhe << carteira                                               # carteira                              9[03]
          detalhe << ''.rjust(21, ' ')                                      # identificacao da operacao no banco    X[21]
          detalhe << codigo_carteira                                        # codigo da carteira                    X[01]
          detalhe << pagamento.identificacao_ocorrencia                     # identificacao ocorrencia              9[02]
          detalhe << pagamento.numero.to_s.rjust(10, '0')                   # numero do documento                   X[10]
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')           # data do vencimento                    9[06]
          detalhe << pagamento.formata_valor                                # valor do documento                    9[13]
          detalhe << cod_banco                                              # codigo banco                          9[03]
          detalhe << ''.rjust(5, '0')                                       # agencia cobradora - deixar zero       9[05]
          detalhe << especie_titulo(pagamento)                              # especie  do titulo                    X[02]
          detalhe << aceite                                                 # aceite (A/N)                          X[01]
          detalhe << pagamento.data_emissao.strftime('%d%m%y')              # data de emissao                       9[06]
          detalhe << pagamento.cod_primeira_instrucao                       # 1a instrucao - deixar zero            X[02]
          detalhe << pagamento.cod_segunda_instrucao                        # 2a instrucao - deixar zero            X[02]
          detalhe << pagamento.formata_valor_mora                           # valor mora ao dia                     9[13]
          detalhe << pagamento.formata_data_desconto                        # data limite para desconto             9[06]
          detalhe << pagamento.formata_valor_desconto                       # valor do desconto                     9[13]
          detalhe << pagamento.formata_valor_iof                            # valor do iof                          9[13]
          detalhe << pagamento.formata_valor_abatimento                     # valor do abatimento                   9[13]
          detalhe << pagamento.identificacao_sacado                         # identificacao do pagador              9[02]
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')         # documento do pagador                  9[14]
          detalhe << pagamento.nome_sacado.format_size(30)                  # nome do pagador                       X[30]
          detalhe << ''.rjust(10, ' ')                                      # complemento do registro (brancos)     X[10]
          detalhe << pagamento.endereco_sacado.format_size(40)              # endereco do pagador                   X[40]
          detalhe << pagamento.bairro_sacado.format_size(12)                # bairro do pagador                     X[12]
          detalhe << pagamento.cep_sacado                                   # cep do pagador                        9[08]
          detalhe << pagamento.cidade_sacado.format_size(15)                # cidade do pagador                     X[15]
          detalhe << pagamento.uf_sacado                                    # uf do pagador                         X[02]
          detalhe << pagamento.nome_avalista.format_size(30)                # nome do sacador/avalista              X[30]
          detalhe << ''.rjust(4, ' ')                                       # complemento do registro               X[04]
          detalhe << ''.rjust(6, '0')                                       # data da mora                          9[06] *
          detalhe << prazo_instrucao(pagamento)                             # prazo para a instrução          9[02]
          detalhe << ''.rjust(1, ' ')                                       # complemento do registro (brancos)     X[01]
          detalhe << sequencial.to_s.rjust(6, '0')                          # numero do registro no arquivo         9[06]
          detalhe
        end

        def prazo_instrucao(pagamento)
          return '03' unless pagamento.cod_primeira_instrucao == '09'
          pagamento.dias_protesto.rjust(2, '0')
        end

        def monta_detalhe_multa(pagamento, sequencial)
          detalhe = '2'
          detalhe << pagamento.codigo_multa
          detalhe << pagamento.data_vencimento.strftime('%d%m%Y')
          detalhe << pagamento.formata_percentual_multa(13)
          detalhe << ''.rjust(371, ' ')
          detalhe << sequencial.to_s.rjust(6, '0')
          detalhe
        end

        # Gera o arquivo com os registros
        #
        # @return [String]
        def gera_arquivo
          fail Brcobranca::RemessaInvalida.new(self) unless self.valid?

          # contador de registros no arquivo
          contador = 1
          ret = [monta_header]
          pagamentos.each do |pagamento|
            contador += 1
            ret << monta_detalhe(pagamento, contador)
            if [VALOR_EM_REAIS, VALOR_EM_PERCENTUAL].include? pagamento.codigo_multa
              contador += 1
              ret << monta_detalhe_multa(pagamento, contador)
            end
          end
          ret << monta_trailer(contador + 1)
          ret.join("\r\n").to_ascii.upcase
        end
      end
    end
  end
end
