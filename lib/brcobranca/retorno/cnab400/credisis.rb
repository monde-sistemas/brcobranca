# -*- encoding: utf-8 -*-
require 'parseline'

module Brcobranca
  module Retorno
    module Cnab400
      # Formato de Retorno CNAB 400
      class Credisis < Brcobranca::Retorno::Base
        extend ParseLine::FixedWidth

        def self.load_lines(file, options = {})
          default_options = { except: [1] } # por padrao ignora a primeira linha que é header
          options = default_options.merge!(options)

          super file, options
        end

        fixed_width_layout do |parse|
          parse.field :codigo_registro, 0..0
          parse.field :nosso_numero, 56..75
          parse.field :data_vencimento, 146..151
          parse.field :valor_titulo, 152..164
          parse.field :data_credito, 175..180
          parse.field :valor_recebido, 253..265
          parse.field :sequencial, 394..399
        end
      end
    end
  end
end
