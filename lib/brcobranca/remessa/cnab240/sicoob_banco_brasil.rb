# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab240
      class SicoobBancoBrasil < Brcobranca::Remessa::Cnab240::BaseCorrespondente
        attr_accessor :codigo_cobranca

        validates_length_of :agencia, is: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :convenio, is: 10, message: 'deve ter 10 dígitos.'
        validates_length_of :conta_corrente, maximum: 10, message: 'deve ter 10 dígitos.'
        validates_length_of :codigo_cobranca, is: 7, message: 'deve ter 7 dígitos.'

        def initialize(campos = {})
          campos = {
            emissao_boleto: '2',
            distribuicao_boleto: '2',
            codigo_carteira: '9',
            tipo_documento: '02'
          }.merge!(campos)
          super(campos)
        end

        def cod_banco
          '756'
        end

        def digito_conta
          conta_corrente.modulo11(mapeamento: { 10 => 'X' }).to_s
        end

        def info_conta
          # CAMPO                  TAMANHO
          # agencia                4
          # codigo cobranca        7
          # conta corrente         11
          "#{agencia.rjust(4, '0')}#{codigo_cobranca.rjust(7, '0')}#{conta_corrente.rjust(10, '0')}#{digito_conta}"
        end

        def complemento_header
          "#{''.rjust(11, '0')}#{''.rjust(33, ' ')}"
        end

        # Monta o registro segmento P do arquivo
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        #   objeto contendo os detalhes do boleto (valor, vencimento, sacado, etc)
        # @param nro_lote [Integer]
        #   numero do lote que o segmento esta inserido
        # @param sequencial [Integer]
        #   numero sequencial do registro no lote
        #
        # @return [String]
        #
        def monta_segmento_p(pagamento, nro_lote, sequencial)
          #                                                             # DESCRICAO                             TAMANHO
          segmento_p = ''.rjust(7, '0')                                 # codigo banco                          7
          segmento_p << '3'                                             # tipo de registro                      1
          segmento_p << sequencial.to_s.rjust(5, '0')                   # num. sequencial do registro no lote   5
          segmento_p << 'P'                                             # cod. segmento                         1
          segmento_p << ' '                                             # uso exclusivo                         1
          segmento_p << '01'                                            # cod. movimento remessa                2
          segmento_p << ''.rjust(23, ' ')                               # brancos                               23
          segmento_p << formata_nosso_numero(pagamento.nosso_numero)    # uso exclusivo                         17
          segmento_p << codigo_carteira                                 # codigo da carteira                    1
          segmento_p << tipo_documento                                  # tipo de documento                     2
          segmento_p << emissao_boleto                                  # identificaco emissao                  1
          segmento_p << ' '                                             # branco                                1
          segmento_p << complemento_p(pagamento)                        # informacoes da conta                  15
          segmento_p << pagamento.data_vencimento.strftime('%d%m%Y')    # data de venc.                         8
          segmento_p << pagamento.formata_valor(15)                     # valor documento                       15
          segmento_p << ''.rjust(6, '0')                                # zeros                                 6
          segmento_p << aceite                                          # aceite                                1
          segmento_p << '  '                                            # brancos                               2
          segmento_p << pagamento.data_emissao.strftime('%d%m%Y')       # data de emissao titulo                8
          segmento_p << '1'                                             # tipo da mora                          1
          segmento_p << pagamento.formata_valor_mora(15).to_s           # valor da mora                         15
          segmento_p << ''.rjust(9, '0')                                # zeros                                 9
          segmento_p << pagamento.formata_data_desconto('%d%m%Y')       # data desconto                         8
          segmento_p << pagamento.formata_valor_desconto(15)            # valor desconto                        15
          segmento_p << ''.rjust(15, ' ')                               # filler                                15
          segmento_p << pagamento.formata_valor_abatimento(15)          # valor abatimento                      15
          segmento_p << ''.rjust(25, ' ')                               # identificacao titulo empresa          25
          segmento_p << codigo_protesto                                 # cod. para protesto                    1
          segmento_p << '00'                                            # dias para protesto                    2
          segmento_p << ''.rjust(4, '0')                                # zero                                  4
          segmento_p << '09'                                            # cod. da moeda                         2
          segmento_p << ''.rjust(10, '0')                               # uso exclusivo                         10
          segmento_p << '0'                                             # zero                                  1
          segmento_p
        end


        def complemento_p(pagamento)
          # CAMPO                   TAMANHO
          # num. doc. de corbanca   15
          "#{pagamento.nosso_numero.to_s.rjust(15, '0')}"
        end

        def codigo_convenio
          # CAMPO                TAMANHO
          # num. convenio        20 BRANCOS
          ''.rjust(20, ' ')
        end

        alias_method :convenio_lote, :codigo_convenio

        # Retorna o nosso numero
        #
        # @return [String]
        #
        def formata_nosso_numero(nosso_numero)
          "#{convenio.to_s.rjust(10, '0')}#{nosso_numero.to_s.rjust(7, '0')}"
        end

        def complemento_trailer
          ''.rjust(217, ' ')
        end

        def totaliza_valor_titulos
          pagamentos.inject(0) { |sum, pag| sum += pag.valor.to_f }
        end

        def valor_titulos_carteira
          total = sprintf "%.2f", totaliza_valor_titulos
          total.somente_numeros.rjust(17, "0")
        end

        # Monta o registro trailer do arquivo
        #
        # @param nro_lotes [Integer]
        #   numero de lotes no arquivo
        # @param sequencial [Integer]
        #   numero de registros(linhas) no arquivo
        #
        # @return [String]
        #
        def monta_trailer_arquivo(nro_lotes, sequencial)
          # CAMPO                     TAMANHO
          # zeros                     7
          # registro trailer lote     1
          # uso FEBRABAN              9
          # nro de lotes              6
          # nro de registros(linhas)  6
          # uso FEBRABAN              211
          "#{''.rjust(7, '0')}5#{''.rjust(9, ' ')}#{nro_lotes.to_s.rjust(6, '0')}#{valor_titulos_carteira}#{''.rjust(6, '0')}#{''.rjust(194, ' ')}"
        end
      end
    end
  end
end
