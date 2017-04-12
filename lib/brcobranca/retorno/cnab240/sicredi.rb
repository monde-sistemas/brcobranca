# -*- encoding: utf-8 -*-
module Brcobranca
  module Retorno
    module Cnab240
      class Sicredi < Brcobranca::Retorno::RetornoCnab240
        class Line < Brcobranca::Retorno::RetornoCnab240::Line
          fixed_width_layout do |parse|
            parse.field :nosso_numero, 37..56
          end
        end
      end
    end
  end
end
