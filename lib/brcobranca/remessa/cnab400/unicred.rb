# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab400
      class Unicred < Brcobranca::Remessa::Cnab400::Base
        # documento do cedente
        attr_accessor :documento_cedente
        # Codigo de transmissao fornecido pelo banco
        attr_accessor :codigo_transmissao

        validates_presence_of :agencia, :conta_corrente, message: 'não pode estar em branco.'
        validates_presence_of :documento_cedente, :digito_conta, message: 'não pode estar em branco.'
        validates_presence_of :codigo_transmissao, message: 'não pode estar em branco.'

        validates_length_of :agencia, maximum: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :conta_corrente, maximum: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :documento_cedente, minimum: 11, maximum: 14, message: 'deve ter entre 11 e 14 dígitos.'
        validates_length_of :carteira, maximum: 2, message: 'deve ter 2 dígitos.'
        validates_length_of :digito_conta, maximum: 1, message: 'deve ter 1 dígito.'
        validates_length_of :codigo_transmissao, maximum: 20, message: 'deve ter 20 dígitos.'

        validates_inclusion_of :carteira, in: %w(01 03 04 05 06 07), message: 'não é válida.'

        # Nova instancia do Unicred
        def initialize(campos = {})
          campos = {
            aceite: 'N'
          }.merge!(campos)

          super(campos)
        end

        def agencia=(valor)
          @agencia = valor.to_s.rjust(4, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(5, '0') if valor
        end

        def carteira=(valor)
          @carteira = valor.to_s.rjust(2, '0') if valor
        end

        def cod_banco
          '748'
        end

        def nome_banco
          'UNICRED'.ljust(15, ' ')
        end

        # Informacoes da conta corrente do cedente
        #
        # @return [String]
        #
        def info_conta
          # CAMPO                    TAMANHO
          # codigo da transmissao         20
          "#{codigo_transmissao}"
        end

        # Complemento do header
        # (no caso do Unicred, sao apenas espacos em branco)
        #
        # @return [String]
        #
        def complemento
          ''.rjust(294, ' ')
        end

        # Codigo da carteira de acordo com a documentacao do Unicred
        #
        # @return [String]
        #
        def codigo_carteira
          codigo_carteira = carteira[1]
        end

        # Dígito verificador do nosso número.
        #
        # @param nosso_numero
        #
        # @return [String] 1 caracteres numéricos.
        def digito_nosso_numero(nosso_numero)
          nosso_numero.to_s.rjust(7, '0').modulo11(
            multiplicador: (2..9).to_a,
            mapeamento: { 1 => 0, 10 => 1, 11 => 0 }
          ) { |total| 11 - (total % 11) }
        end

        def informacao_multa(pagamento)
          return "0" if pagamento.percentual_multa.blank?
          pagamento.percentual_multa.to_i > 0 ? "4" : "0"
        end

        def identificador_complemento
          " "
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
          detalhe << codigo_transmissao                                     # código da transmissao                 9[20]
          detalhe << ''.rjust(25, ' ')                                      # numero de controle do participante    X[25]
          detalhe << pagamento.nosso_numero.to_s.rjust(7, '0')              # nosso numero                          9[07]
          detalhe << digito_nosso_numero(pagamento.nosso_numero).to_s       # dv do nosso numero                    9[01]
          detalhe << pagamento.formata_data_segundo_desconto                # data do segundo desconto              9[06]
          detalhe << ' '                                                    # branco                                X[01]
          detalhe << informacao_multa(pagamento)                            # informação de multa                   9[01]
          detalhe << pagamento.percentual_multa.to_s.rjust(4, '0')          # taxa - multa                          9[04]
          detalhe << "00"                                                   # código da moeda                       9[02]
          detalhe << ''.rjust(13, '0')                                      # valor do titulo em outra moeda        9[13]
          detalhe << ''.rjust(4, ' ')                                       # brancos                               X[04]
          detalhe << pagamento.formata_data_multa                           # data cobranca da multa                9[06]
          detalhe << codigo_carteira                                        # codigo da carteira                    X[01]
          detalhe << pagamento.identificacao_ocorrencia                     # identificacao ocorrencia              9[02]
          detalhe << pagamento.numero_documento.to_s.rjust(10, '0')         # numero do documento                   X[10]
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')           # data do vencimento                    9[06]
          detalhe << pagamento.formata_valor                                # valor do documento                    9[13]
          detalhe << cod_banco                                              # codigo banco                          9[03]
          detalhe << ''.rjust(5, '0')                                       # agencia cobradora - deixar zero       9[05]
          detalhe << '01'                                                   # especie  do titulo                    X[02]
          detalhe << aceite                                                 # aceite (A/N)                          X[01]
          detalhe << pagamento.data_emissao.strftime('%d%m%y')              # data de emissao                       9[06]
          detalhe << "".rjust(4, "0")                                       # instrucao                             9[04]
          detalhe << pagamento.formata_valor_mora                           # valor mora ao dia                     9[13]
          detalhe << pagamento.formata_data_desconto                        # data limite para desconto             9[06]
          detalhe << pagamento.formata_valor_desconto                       # valor do desconto                     9[13]
          detalhe << pagamento.formata_valor_iof                            # valor do iof                          9[13]
          detalhe << pagamento.formata_valor_abatimento                     # valor do abatimento                   9[11]
          detalhe << pagamento.identificacao_sacado                         # identificacao do pagador              9[02]
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')         # documento do pagador                  9[14]
          detalhe << pagamento.nome_sacado.format_size(40)                  # nome do pagador                       X[40]
          detalhe << pagamento.endereco_sacado.format_size(40)              # endereco do pagador                   X[40]
          detalhe << pagamento.bairro_sacado.format_size(12)                # bairro do pagador                     X[12]
          detalhe << pagamento.cep_sacado                                   # cep do pagador                        9[08]
          detalhe << pagamento.cidade_sacado.format_size(15)                # cidade do pagador                     X[15]
          detalhe << pagamento.uf_sacado                                    # uf do pagador                         X[02]
          detalhe << pagamento.nome_avalista.format_size(30)                # nome do sacador/avalista              X[30]
          detalhe << " "                                                    # brancos                               X[01]
          detalhe << identificador_complemento                              # identificacao complemento             X[01]
          detalhe << "".rjust(2, " ")                                       # complemento                           9[02]
          detalhe << "".rjust(6, " ")                                       # brancos                               X[06]
          detalhe << "00"                                                   # numero de dias para proteste          9[02]
          detalhe << " "                                                    # brancos                               X[01]
          detalhe << sequencial.to_s.rjust(6, '0')                          # numero do registro no arquivo         9[06]
          detalhe
        end
      end
    end
  end
end
