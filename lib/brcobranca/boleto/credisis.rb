# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Credisis < Base # CrediSIS
      MAPEAMENTO_MODULO11 = { 0 => 1, 10 => 1, 11 => 1 }

      validates_length_of :agencia, maximum: 4
      validates_length_of :conta_corrente, maximum: 7
      validates_length_of :carteira, is: 2
      validates_length_of :convenio, maximum: 6
      validates_length_of :numero, maximum: 6

      # Nova instancia do CrediSIS
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = { carteira: '18', codigo_servico: false }.merge!(campos)
        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '097'
      end

      # Carteira
      #
      # @return [String] 2 caracteres numéricos.
      def carteira=(valor)
        @carteira = valor.to_s.rjust(2, '0') if valor
      end

      # Dígito verificador do banco
      #
      # @return [String] 1 caracteres numéricos.
      def banco_dv
        banco.modulo11(mapeamento: MAPEAMENTO_MODULO11)
      end

      # Retorna dígito verificador da agência
      #
      # @return [String] 1 caracteres numéricos.
      def agencia_dv
        agencia.modulo11(mapeamento: MAPEAMENTO_MODULO11)
      end

      # Conta corrente
      # @return [String] 8 caracteres numéricos.
      def conta_corrente=(valor)
        @conta_corrente = valor.to_s.rjust(7, '0') if valor
      end

      # Dígito verificador da conta corrente
      # @return [String] 1 caracteres numéricos.
      def conta_corrente_dv
        conta_corrente.modulo11(mapeamento: MAPEAMENTO_MODULO11)
      end

      # Número sequencial utilizado para identificar o boleto.
      # (Número de dígitos depende do tipo de convênio).
      #
      # @overload numero
      #   Nosso Número de 17 dígitos com Convenio de 7 dígitos e código do cooperado de 4 dígitos. (carteira 18)
      #   @return [String] 17 caracteres numéricos.
      def numero
        @numero.to_s.rjust(6, '0')
      end

      # Dígito verificador do nosso número.
      # @return [String] 1 caracteres numéricos.
      # @see BancoBrasil#numero
      def nosso_numero_dv
        "#{numero}".modulo11(mapeamento: MAPEAMENTO_MODULO11)
      end

      # Nosso número para exibir no boleto.
      # Composição do Nosso Número:
      # 097XAAAACCCCCCSSSSSS
      # 097 Fixo
      # X Módulo 11 do CPF/CNPJ (Incluindo dígitos verificadores) do Beneficiário.
      # AAAA Código da Agência CrediSIS ao qual o Beneficiário possui Conta.
      # CCCCCC Código de Convênio do Beneficiário no Sistema CrediSIS
      # SSSSSS Sequencial Único do Boleto
      #
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "10000000027000095-7"
      def nosso_numero_boleto
        "#{banco}#{documento_cedente_dv}#{agencia.rjust(4, '0')}#{convenio.rjust(6, '0')}#{numero.rjust(6, '0')}"
      end

      def documento_cedente_dv
        documento_cedente.modulo11(mapeamento: MAPEAMENTO_MODULO11)
      end

      # Agência + conta corrente do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0001-9 / 0000002-7"
      def agencia_conta_boleto
        "#{agencia}-#{agencia_dv} / #{conta_corrente}-#{conta_corrente_dv}"
      end

      # Segunda parte do código de barras:
      # 6. - Fixo Zeros: Campo com preenchimento Zerado “00000”
      # 7. - Composição do Nosso Número: 097XAAAACCCCCCSSSSSS
      #
      # @return [String] 25 caracteres numéricos..
      def codigo_barras_segunda_parte
        "#{'0' * 5}#{nosso_numero_boleto}".rjust(25, '0')
      end
    end
  end
end
