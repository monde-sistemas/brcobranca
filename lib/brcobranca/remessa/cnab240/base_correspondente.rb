# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab240
      class BaseCorrespondente < Brcobranca::Remessa::Base
        # documento do cedente (CPF/CNPJ)
        attr_accessor :documento_cedente
        # convenio do cedente
        attr_accessor :convenio
        # mensagem 1
        attr_accessor :mensagem_1
        # mensagem 2
        attr_accessor :mensagem_2
        # codigo da carteira
        #   opcoes:
        #     1 - cobranca simples
        #     2 - cobranca caucionada
        #     3 - cobranca descontada
        #     7 – modalidade Simples quando carteira 17 (apenas Banco do Brasil)
        attr_accessor :codigo_carteira
        # forma de cadastramento dos titulos (campo nao tratado pelo Banco do Brasil)
        #   opcoes:
        #     1 - com cadastramento (cobrança registrada)
        #     2 - sem cadastramento (cobrança sem registro)
        attr_accessor :forma_cadastramento
        # identificacao da emissao do boleto (verificar opcoes nas classes referentes aos bancos)
        attr_accessor :emissao_boleto
        # identificacao da distribuicao do boleto (verificar opcoes nas classes referentes aos bancos)
        attr_accessor :distribuicao_boleto
        # especie do titulo (verificar o padrao nas classes referentes aos bancos)
        attr_accessor :especie_titulo
        # tipo de documento (verificar o padrao nas classes referentes aos bancos)
        attr_accessor :tipo_documento

        validates_presence_of :agencia, :conta_corrente, message: 'não pode estar em branco.'
        validates_presence_of :documento_cedente, message: 'não pode estar em branco.'
        validates_length_of :codigo_carteira, is: 1, message: 'deve ter 1 dígito.'
        validates_length_of :forma_cadastramento, is: 1, message: 'deve ter 1 dígito.'
        validates_length_of :emissao_boleto, is: 1, message: 'deve ter 1 dígito.'
        validates_length_of :distribuicao_boleto, is: 1, message: 'deve ter 1 dígito.'

        def initialize(campos = {})
          campos = { codigo_carteira: '1',
            forma_cadastramento: '1',
            tipo_documento: ' ' }.merge!(campos)
          super(campos)
        end

        # Data de geracao do arquivo
        #
        # @return [String]
        #
        def data_geracao
          Date.today.strftime('%d%m%Y')
        end

        # Hora de geracao do arquivo
        #
        # @return [String]
        #
        def hora_geracao
          (Time.respond_to?(:current) ? Time.current : Time.now).strftime('%H%M%S')
        end

        # Monta o registro header do arquivo
        #
        # @return [String]
        #
        def monta_header_arquivo
          header_arquivo = ''                                   # CAMPO                         TAMANHO
          header_arquivo << cod_banco                           # codigo do banco               3
          header_arquivo << '0000'                              # zeros                         4
          header_arquivo << '1'                                 # registro header do lote       1
          header_arquivo << 'R'                                 # tipo operacao: R-remessa      1
          header_arquivo << ''.rjust(7, '0')                    # zeros                         7
          header_arquivo << ''.rjust(2, ' ')                    # brancos                       2
          header_arquivo << info_conta                          # informacoes da conta          22
          header_arquivo << ''.rjust(30, ' ')                   # brancos                       30
          header_arquivo << empresa_mae.format_size(30)         # nome da empresa               30
          header_arquivo << ''.rjust(80, ' ')                   # brancos                       80
          header_arquivo << sequencial_remessa.to_s.rjust(8, '0') # numero seq. arquivo         8
          header_arquivo << data_geracao                        # data geracao                  8
          header_arquivo << complemento_header                  # complemento do arquivo        44
          header_arquivo
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
          # campos com * na frente nao foram implementados
          #                                                             # DESCRICAO                             TAMANHO
          segmento_p = cod_banco # codigo banco                          3
          segmento_p << nro_lote.to_s.rjust(4, '0') # lote de servico                       4
          segmento_p << '3' # tipo de registro                      1
          segmento_p << sequencial.to_s.rjust(5, '0') # num. sequencial do registro no lote   5
          segmento_p << 'P' # cod. segmento                         1
          segmento_p << ' ' # uso exclusivo                         1
          segmento_p << '01' # cod. movimento remessa                2
          segmento_p << agencia.to_s.rjust(5, '0') # agencia                               5
          segmento_p << digito_agencia.to_s # dv agencia                            1
          segmento_p << complemento_p(pagamento) # informacoes da conta                  34
          segmento_p << codigo_carteira # codigo da carteira                    1
          segmento_p << forma_cadastramento # forma de cadastro do titulo           1
          segmento_p << tipo_documento # tipo de documento                     1
          segmento_p << emissao_boleto # identificaco emissao                  1
          segmento_p << distribuicao_boleto # indentificacao entrega                1
          segmento_p << pagamento.numero_documento.to_s.rjust(15, '0') # uso exclusivo                         4
          segmento_p << pagamento.data_vencimento.strftime('%d%m%Y') # data de venc.                         8
          segmento_p << pagamento.formata_valor(15) # valor documento                       15
          segmento_p << ''.rjust(5, '0') # agencia cobradora                     5
          segmento_p << '0' # dv agencia cobradora                  1
          segmento_p << especie_titulo # especie do titulo                     2
          segmento_p << aceite # aceite                                1
          segmento_p << pagamento.data_emissao.strftime('%d%m%Y') # data de emissao titulo                8
          segmento_p << '0' # cod. do juros                         1   *
          segmento_p << ''.rjust(8, '0') # data juros                            8   *
          segmento_p << ''.rjust(15, '0') # valor juros                           15  *
          segmento_p << pagamento.cod_desconto # cod. do desconto                      1
          segmento_p << pagamento.formata_data_desconto('%d%m%Y') # data desconto                         8
          segmento_p << pagamento.formata_valor_desconto(15) # valor desconto                        15
          segmento_p << pagamento.formata_valor_iof(15) # valor IOF                             15
          segmento_p << pagamento.formata_valor_abatimento(15) # valor abatimento                      15
          segmento_p << ''.rjust(25, ' ') # identificacao titulo empresa          25  *
          segmento_p << codigo_protesto   # cod. para protesto                    1   *
          segmento_p << '00' # dias para protesto                    2   *
          segmento_p << '0' # cod. para baixa                       1   *
          segmento_p << '000' # dias para baixa                       2   *
          segmento_p << '09' # cod. da moeda                         2
          segmento_p << ''.rjust(10, '0') # uso exclusivo                         10
          segmento_p << ' ' # uso exclusivo                         1
          segmento_p
        end

        # Monta o registro segmento Q do arquivo
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
        def monta_segmento_q(pagamento, nro_lote, sequencial)
          segmento_q = '' # CAMPO                                TAMANHO
          segmento_q << cod_banco # codigo banco                         3
          segmento_q << nro_lote.to_s.rjust(4, '0') # lote de servico                      4
          segmento_q << '3' # tipo de registro                     1
          segmento_q << sequencial.to_s.rjust(5, '0') # num. sequencial do registro no lote  5
          segmento_q << 'Q' # cod. segmento                        1
          segmento_q << ' ' # uso exclusivo                        1
          segmento_q << '01' # cod. movimento remessa               2
          segmento_q << pagamento.identificacao_sacado(false) # tipo insc. sacado                    1
          segmento_q << pagamento.documento_sacado.to_s.rjust(15, '0') # documento sacado                     14
          segmento_q << pagamento.nome_sacado.format_size(40) # nome cliente                         40
          segmento_q << pagamento.endereco_sacado.format_size(40) # endereco cliente                     40
          segmento_q << pagamento.bairro_sacado.format_size(15) # bairro                               15
          segmento_q << pagamento.cep_sacado[0..4] # cep                                  5
          segmento_q << pagamento.cep_sacado[5..7] # sufixo cep                           3
          segmento_q << pagamento.cidade_sacado.format_size(15) # cidade                               15
          segmento_q << pagamento.uf_sacado # uf                                   2
          segmento_q << pagamento.identificacao_avalista(false) # identificacao do sacador             1
          segmento_q << pagamento.documento_avalista.to_s.rjust(15, '0') # documento sacador                    15
          segmento_q << pagamento.nome_avalista.format_size(40) # nome avalista                         40
          segmento_q << ''.rjust(3, '0') # cod. banco correspondente            3
          segmento_q << ''.rjust(20, ' ') # nosso numero banco correspondente    20
          segmento_q << ''.rjust(8, ' ') # uso exclusivo                        8
          segmento_q
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
          # codigo banco              3
          # lote de servico           4
          # tipo de registro          1
          # uso FEBRABAN              9
          # nro de lotes              6
          # nro de registros(linhas)  6
          # uso FEBRABAN              211
          "#{cod_banco}99999#{''.rjust(9, ' ')}#{nro_lotes.to_s.rjust(6, '0')}#{sequencial.to_s.rjust(6, '0')}#{''.rjust(211, ' ')}"
        end

        # Monta um lote para o arquivo
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        #   objeto contendo os detalhes do boleto (valor, )
        #
        # @param nro_lote [Integer]
        # numero do lote no arquivo
        #
        # @return [Array]
        #
        def monta_lote(nro_lote)
          # contador dos registros do lote
          contador = 1 #header

          lote = []

          pagamentos.each do |pagamento|
            fail Brcobranca::RemessaInvalida.new(pagamento) if pagamento.invalid?

            lote << monta_segmento_p(pagamento, nro_lote, contador)
            contador += 1
            lote << monta_segmento_q(pagamento, nro_lote, contador)
            contador += 1
          end
          contador += 1 #trailer

          lote
        end

        # Gera o arquivo remessa
        #
        # @return [String]
        #
        def gera_arquivo
          fail Brcobranca::RemessaInvalida.new(self) if self.invalid?

          arquivo = [monta_header_arquivo]

          # contador de do lotes
          contador = 1
          arquivo.push monta_lote(contador)

          arquivo << monta_trailer_arquivo(contador, ((pagamentos.size * 2) + (contador * 2) + 2))

          arquivo.join("\r\n").to_ascii.upcase
        end

        # Complemento do registro
        #
        # Este metodo deve ser sobrescrevido na classe do banco
        #
        def complemento_header
          fail Brcobranca::NaoImplementado.new('Sobreescreva este método na classe referente ao banco que você esta criando')
        end

        # Informacoes do convenio para o lote
        #
        # Este metodo deve ser sobrescrevido na classe do banco
        #
        def convenio_lote
          fail Brcobranca::NaoImplementado.new('Sobreescreva este método na classe referente ao banco que você esta criando')
        end

        # Codigo do banco
        #
        # Este metodo deve ser sobrescrevido na classe do banco
        #
        def cod_banco
          fail Brcobranca::NaoImplementado.new('Sobreescreva este método na classe referente ao banco que você esta criando')
        end

        # Informacoes da conta do cedente
        #
        # Este metodo deve ser sobrescrevido na classe do banco
        #
        def info_conta
          fail Brcobranca::NaoImplementado.new('Sobreescreva este método na classe referente ao banco que você esta criando')
        end

        # Codigo do convenio
        #
        # Este metodo deve ser sobrescrevido na classe do banco
        #
        def codigo_convenio
          fail Brcobranca::NaoImplementado.new('Sobreescreva este método na classe referente ao banco que você esta criando')
        end

        # Codigo para protesto
        #
        # Sobreescreva caso necessário
        def codigo_protesto
          "0"
        end
      end
    end
  end
end
