# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab240
      class Sicoob < Brcobranca::Remessa::Cnab240::Base

        attr_accessor :modalidade_carteira
        # identificacao da emissao do boleto (attr na classe base)
        #   opcoes:
        #     ‘1’ = Banco Emite
        #     ‘2’ = Cliente Emite
        #
        # identificacao da distribuicao do boleto (attr na classe base)
        #   opcoes:
        #     ‘1’ = Banco distribui
        #     ‘2’ = Cliente distribui

        attr_accessor :tipo_formulario
        #       Tipo Formulário - 01 posição  (15 a 15):
        #            "1" -auto-copiativo
        #            "3" -auto-envelopável
        #            "4" -A4 sem envelopamento
        #            "6" -A4 sem envelopamento 3 vias

        attr_accessor :parcela
        #       Parcela - 02 posições (11 a 12) - "01" se parcela única

        validates_presence_of :modalidade_carteira, :tipo_formulario, :parcela, message: 'não pode estar em branco.'
        # Remessa 400 - 8 digitos
        # Remessa 240 - 12 digitos
        validates_length_of :conta_corrente, maximum: 8, message: 'deve ter 8 dígitos.'
        validates_length_of :agencia, is: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :modalidade_carteira, is: 2, message: 'deve ter 2 dígitos.'

        def initialize(campos = {})
          campos = { emissao_boleto: '2',
            distribuicao_boleto: '2',
            especie_titulo: '02',
            tipo_formulario: '4',
            parcela: '01',
            modalidade_carteira: '01',
            forma_cadastramento: '0'}.merge!(campos)
          super(campos)
        end

        def cod_banco
          '756'
        end

        def nome_banco
          'SICOOB'.ljust(30, ' ')
        end

        def versao_layout_arquivo
          '081'
        end

        def versao_layout_lote
          '040'
        end

        def digito_agencia
          # utilizando a agencia com 4 digitos
          # para calcular o digito
          agencia.modulo11(mapeamento: { 10 => 'X' }).to_s
        end

        def digito_conta
          # utilizando a conta corrente com 5 digitos
          # para calcular o digito
          conta_corrente.modulo11(mapeamento: { 10 => '0' }).to_s
        end

        def codigo_convenio
          # CAMPO                TAMANHO
          # num. convenio        20 BRANCOS
          ''.rjust(20, ' ')
        end

        alias_method :convenio_lote, :codigo_convenio

        def info_conta
          # CAMPO                  TAMANHO
          # agencia                5
          # digito agencia         1
          # conta corrente         12
          # digito conta           1
          # digito agencia/conta   1
          "#{agencia.rjust(5, '0')}#{digito_agencia}#{conta_corrente.rjust(12, '0')}#{digito_conta} "
        end

        def complemento_header
          ''.rjust(29, ' ')
        end

        def quantidade_titulos_cobranca
          pagamentos.length.to_s.rjust(6, "0")
        end

        def totaliza_valor_titulos
          pagamentos.inject(0) { |sum, pag| sum += pag.valor.to_f }
        end

        def valor_titulos_carteira
          total = sprintf "%.2f", totaliza_valor_titulos
          total.somente_numeros.rjust(17, "0")
        end

        def complemento_trailer
          # CAMPO                               TAMANHO
          # Qt. Títulos em Cobrança Simples     6
          # Vl. Títulos em Carteira Simples     15 + 2 decimais
          # Qt. Títulos em Cobrança Vinculada   6
          # Vl. Títulos em Carteira Vinculada   15 + 2 decimais
          # Qt. Títulos em Cobrança Caucionada  6
          # Vl. Títulos em Carteira Caucionada  15 + 2 decimais
          # Qt. Títulos em Cobrança Descontada  6
          # Vl. Títulos em Carteira Descontada  15 + 2 decimais
          total_cobranca_simples    = "#{quantidade_titulos_cobranca}#{valor_titulos_carteira}"
          total_cobranca_vinculada  = "".rjust(23, "0")
          total_cobranca_caucionada = "".rjust(23, "0")
          total_cobranca_descontada = "".rjust(23, "0")

          "#{total_cobranca_simples}#{total_cobranca_vinculada}#{total_cobranca_caucionada}"\
            "#{total_cobranca_descontada}".ljust(217, ' ')
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
          "#{cod_banco}99999#{''.rjust(9, ' ')}#{nro_lotes.to_s.rjust(6, '0')}#{sequencial.to_s.rjust(6, '0')}#{''.rjust(6, '0')}#{''.rjust(205, ' ')}"
        end

        def complemento_p(pagamento)
          # CAMPO                   TAMANHO
          # conta corrente          12
          # digito conta            1
          # digito agencia/conta    1
          # ident. titulo no banco  20
          "#{conta_corrente.rjust(12, '0')}#{digito_conta} #{formata_nosso_numero(pagamento.nosso_numero)}"
        end

        # Retorna o nosso numero
        #
        # @return [String]
        #
        # Nosso Número:
        #  - Se emissão a cargo do Cedente (vide planilha "Capa" deste arquivo):
        #       NumTitulo - 10 posições (1 a 10)
        #       Parcela - 02 posições (11 a 12) - "01" se parcela única
        #       Modalidade - 02 posições (13 a 14) - vide planilha "Capa" deste arquivo
        #       Tipo Formulário - 01 posição  (15 a 15):
        #            "1" -auto-copiativo
        #            "3" -auto-envelopável
        #            "4" -A4 sem envelopamento
        #            "6" -A4 sem envelopamento 3 vias
        #       Em branco - 05 posições (16 a 20)
        def formata_nosso_numero(nosso_numero)
          "#{nosso_numero.to_s.rjust(10, '0')}#{parcela}#{modalidade_carteira}#{tipo_formulario}     "
        end
      end
    end
  end
end
