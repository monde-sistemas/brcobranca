# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Credisis < Base # CrediSIS
      validates_length_of :agencia, maximum: 4, message: 'deve ser menor ou igual a 4 dígitos.'
      validates_length_of :conta_corrente, maximum: 8, message: 'deve ser menor ou igual a 8 dígitos.'
      validates_length_of :carteira, maximum: 2, message: 'deve ser menor ou igual a 2 dígitos.'
      validates_length_of :convenio, in: 4..8, message: 'não existente para este banco.'

      validates_length_of :numero_documento, maximum: 6, message: 'deve ser menor ou igual a 6 dígitos.'

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
        banco.modulo11(mapeamento: { 10 => 'X' })
      end

      # Retorna dígito verificador da agência
      #
      # @return [String] 1 caracteres numéricos.
      def agencia_dv
        agencia.modulo11(mapeamento: { 10 => 'X' })
      end

      # Conta corrente
      # @return [String] 8 caracteres numéricos.
      def conta_corrente=(valor)
        @conta_corrente = valor.to_s.rjust(8, '0') if valor
      end

      # Dígito verificador da conta corrente
      # @return [String] 1 caracteres numéricos.
      def conta_corrente_dv
        conta_corrente.modulo11(mapeamento: { 10 => 'X' })
      end

      # Número seqüencial utilizado para identificar o boleto.
      # (Número de dígitos depende do tipo de convênio).
      # @raise  [Brcobranca::NaoImplementado] Caso o tipo de convênio não seja suportado pelo Brcobranca.
      #
      # @overload numero_documento
      #   Nosso Número de 17 dígitos com Convenio de 7 dígitos e código do cooperado de 4 dígitos. (carteira 18)
      #   @return [String] 17 caracteres numéricos.
      def numero_documento
        @numero_documento.to_s.rjust(6, '0')
      end

      # Dígito verificador do nosso número.
      # @return [String] 1 caracteres numéricos.
      # @see BancoBrasil#numero_documento
      def nosso_numero_dv
        "#{convenio}#{numero_documento}".modulo11(mapeamento: { 10 => 'X' })
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "12387989000004042-4"
      def nosso_numero_boleto
        "#{convenio}#{numero_documento}"
      end

      # Agência + conta corrente do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0548-7 / 00001448-6"
      def agencia_conta_boleto
        "#{agencia}-#{agencia_dv} / #{conta_corrente}-#{conta_corrente_dv}"
      end

      # Segunda parte do código de barras.
      # A montagem é feita baseada na quantidade de dígitos do convênio.
      # @return [String] 25 caracteres numéricos.
      def codigo_barras_segunda_parte
        case convenio.to_s.size
        when 8 # Nosso Número de 17 dígitos com Convenio de 8 dígitos e numero_documento de 9 dígitos
          "000000#{convenio}#{numero_documento}#{carteira}"
        when 7 # Nosso Número de 17 dígitos com Convenio de 7 dígitos e numero_documento de 10 dígitos
          "000000#{convenio}#{numero_documento}#{carteira}"
        when 6 # Convenio de 6 dígitos
          if codigo_servico == false
            # Nosso Número de 11 dígitos com Convenio de 6 dígitos e numero_documento de 5 dígitos
            "#{convenio}#{numero_documento}#{agencia}#{conta_corrente}#{carteira}"
          else
            # Nosso Número de 17 dígitos com Convenio de 6 dígitos e sem numero_documento, carteira 16 e 18
            fail "Só é permitido emitir boletos com nosso número de 17 dígitos com carteiras 16 ou 18. Sua carteira atual é #{carteira}" unless %w(16 18).include?(carteira)
            "#{convenio}#{numero_documento}21"
          end
        when 4 # Nosso Número de 7 dígitos com Convenio de 4 dígitos e sem numero_documento
          "#{convenio}#{numero_documento}#{agencia}#{conta_corrente}#{carteira}"
        end
      end
    end
  end
end
