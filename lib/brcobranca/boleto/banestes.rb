# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Banestes < Base # Sicoob (Bancoob)
      validates_length_of :agencia, maximum: 4
      validates_length_of :conta_corrente, maximum: 11
      validates_length_of :numero, maximum: 8
      validates_length_of :variacao, maximum: 1
      validates_length_of :carteira, maximum: 2

      def initialize(campos = {})
        campos = { carteira: "11", variacao: '2' }.merge!(campos)
        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        "021"
      end

      # Dígito verificador do banco
      #
      # @return [String] 1 caractere.
      def banco_dv
        "3"
      end

      # Agência
      #
      # @return [String] 4 caracteres numéricos.
      def agencia=(valor)
        @agencia = valor.to_s.rjust(4, "0") if valor
      end

      # Conta
      #
      # @return [String] 7 caracteres numéricos.
      def conta_corrente=(valor)
        @conta_corrente = valor.to_s.rjust(11, "0") if valor
      end

      # Número documento
      #
      # @return [String] 8 caracteres numéricos.
      def numero=(valor)
        @numero = valor.to_s.rjust(8, "0") if valor
      end

      # Nosso número para exibição no boleto.
      #
      # @return [String] caracteres numéricos.
      def nosso_numero_boleto
        "#{numero}-#{nosso_numero_dv}"
      end

      def nosso_numero_dv
        numero_dv_1 = numero.modulo11(mapeamento: { 10 => 0, 11 => 0 })
        numero_dv_2 = "#{numero}#{numero_dv_1}".modulo11

        "#{numero_dv_1}#{numero_dv_2}"
      end

      def agencia_conta_boleto
        "#{agencia} / #{conta_corrente}"
      end


      # Nosso Numero 'N'        | Nosso número sem os dígitos                                    | 08
      # Conta corrente 'C'      | No da conta corrente                                             | 11
      # Tipo Cobranca 'R'       | (2) Sem registro - (3) Caucionada - (4, 5, 6 e 7) Com registro   | 01
      # Codigo do banco cedente | Código do BANESTES '021'                                        | 03
      # Digitos                 | Dígitos verificadores                                           | 02
      def codigo_barras_segunda_parte
        campo_livre = "#{numero}#{conta_corrente}#{variacao}021"
        campo_livre + campo_livre.duplo_digito
      end
    end
  end
end
