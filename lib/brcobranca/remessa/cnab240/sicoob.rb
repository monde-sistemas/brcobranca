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

        attr_accessor :posto
        # Mantém a informação do posto de atendimento dentro da agência.

        validates_presence_of :modalidade_carteira, :tipo_formulario, :parcela, :convenio
        # Remessa 400 - 8 digitos
        # Remessa 240 - 12 digitos
        validates_length_of :conta_corrente, maximum: 8
        validates_length_of :agencia, is: 4
        validates_length_of :modalidade_carteira, is: 2

        def initialize(campos = {})
          campos = { emissao_boleto: '2',
                     distribuicao_boleto: '2',
                     tipo_formulario: '4',
                     parcela: '01',
                     modalidade_carteira: '01',
                     forma_cadastramento: '0',
                     posto: '00' }.merge!(campos)
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

        def especie_titulo_padrao
          '02'
        end

        def uso_exclusivo_banco
          ''.rjust(20, ' ')
        end

        def uso_exclusivo_empresa
          ''.rjust(20, ' ')
        end

        def digito_agencia
          # utilizando a agencia com 4 digitos
          # para calcular o digito
          agencia.modulo11(mapeamento: { 10 => '0' }).to_s
        end

        def digito_conta
          # utilizando a conta corrente com 5 digitos
          # para calcular o digito
          conta_corrente.modulo11(mapeamento: { 10 => '0' }).to_s
        end

        def dv_agencia_cobradora
          ' '
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
          "#{agencia.rjust(5, '0')}#{digito_agencia}#{conta_corrente.rjust(12, '0')}#{digito_conta}0"
        end

        # Monta o registro header do lote
        #
        # @param nro_lote [Integer]
        #   numero do lote no arquivo (iterar a cada novo lote)
        #
        # @return [String]
        #
        def monta_header_lote(nro_lote)
          header_lote = ''                                      # CAMPO                   TAMANHO
          header_lote << cod_banco                              # codigo banco            3
          header_lote << nro_lote.to_s.rjust(4, '0')            # lote servico            4
          header_lote << '1'                                    # tipo de registro        1
          header_lote << 'R'                                    # tipo de operacao        1
          header_lote << '01'                                   # tipo de servico         2
          header_lote << exclusivo_servico                      # uso exclusivo           2
          header_lote << versao_layout_lote                     # num.versao layout lote  3
          header_lote << ' '                                    # uso exclusivo           1
          header_lote << Brcobranca::Util::Empresa.new(documento_cedente, false).tipo # tipo de inscricao       1
          header_lote << documento_cedente.to_s.rjust(15, '0')  # inscricao cedente       15
          header_lote << convenio_lote                          # codigo do convenio      20
          header_lote << info_conta[0..18] + ' '                # informacoes conta       20
          header_lote << empresa_mae.format_size(30)            # nome empresa            30
          header_lote << mensagem_1.to_s.format_size(40)        # 1a mensagem             40
          header_lote << mensagem_2.to_s.format_size(40)        # 2a mensagem             40
          header_lote << sequencial_remessa.to_s.rjust(8, '0')  # numero remessa          8
          header_lote << data_geracao                           # data gravacao           8
          header_lote << ''.rjust(8, '0')                       # data do credito         8
          header_lote << ''.rjust(33, ' ')                      # complemento             33
          header_lote
        end
        def complemento_header
          ''.rjust(29, ' ')
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
          total_cobranca_vinculada  = ''.rjust(23, '0')
          total_cobranca_caucionada = ''.rjust(23, '0')
          total_cobranca_descontada = ''.rjust(23, '0')

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

        def data_multa(pagamento)
          return ''.rjust(8, '0') if pagamento.codigo_multa == '0'

          pagamento.formata_proximo_dia_apos_data_vencimento
        end

        def data_mora(pagamento)
          return ''.rjust(8, '0') unless %w[1 2].include? pagamento.codigo_mora

          pagamento.formata_proximo_dia_apos_data_vencimento
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

        def dias_baixa(_pagamento)
          ''.rjust(3, ' ')
        end

        def incluir_segmento_s?
          true
        end
      end
    end
  end
end
