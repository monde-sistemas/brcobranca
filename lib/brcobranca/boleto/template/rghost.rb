# -*- encoding: utf-8 -*-

begin
  require 'rghost'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rghost'
  require 'rghost'
end

begin
  require 'rghost_barcode'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rghost_barcode'
  require 'rghost_barcode'
end

module Brcobranca
  module Boleto
    module Template
      # Templates para usar com Rghost
      module Rghost
        extend self
        include RGhost unless self.include?(RGhost)
        RGhost::Config::GS[:external_encoding] = Brcobranca.configuration.external_encoding

        # Gera o boleto em usando o formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        #
        # @return [Stream]
        # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats Veja mais formatos na documentação do rghost.
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        def to(formato, options = {})
          modelo_generico(self, options.merge!(formato: formato))
        end

        # Gera o boleto em usando o formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        #
        # @return [Stream]
        # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats Veja mais formatos na documentação do rghost.
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        def lote(boletos, options = {})
          modelo_generico_multipage(boletos, options)
        end

        #  Cria o métodos dinâmicos (to_pdf, to_gif e etc) com todos os fomátos válidos.
        #
        # @return [Stream]
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        # @example
        #  @boleto.to_pdf #=> boleto gerado no formato pdf
        def method_missing(m, *args)
          method = m.to_s
          if method.start_with?('to_')
            modelo_generico(self, (args.first || {}).merge!(formato: method[3..-1]))
          else
            super
          end
        end

        private

        # Retorna um stream pronto para gravação em arquivo.
        #
        # @return [Stream]
        # @param [Boleto] Instância de uma classe de boleto.
        # @param [Hash] options Opção para a criação do boleto.
        # @option options [Symbol] :resolucao Resolução em pixels.
        # @option options [Symbol] :formato Formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        def modelo_generico(boleto, options = {})
          doc = Document.new paper: :A4 # 210x297

          template_path = File.join(File.dirname(__FILE__), '..', '..', 'arquivos', 'templates', 'modelo_generico.eps')

          fail 'Não foi possível encontrar o template. Verifique o caminho' unless File.exist?(template_path)

          modelo_generico_template(doc, boleto, template_path)
          modelo_generico_cabecalho(doc, boleto)
          modelo_generico_rodape(doc, boleto)

          # Gerando codigo de barra com rghost_barcode
          doc.barcode_interleaved2of5(boleto.codigo_barras, width: '10.3 cm', height: '1.3 cm', x: "#{@x - 1.7} cm", y: "#{@y - 1.67} cm") if boleto.codigo_barras

          # Gerando stream
          formato = (options.delete(:formato) || Brcobranca.configuration.formato)
          resolucao = (options.delete(:resolucao) || Brcobranca.configuration.resolucao)
          doc.render_stream(formato.to_sym, resolution: resolucao)
        end

        # Retorna um stream para multiplos boletos pronto para gravação em arquivo.
        #
        # @return [Stream]
        # @param [Array] Instâncias de classes de boleto.
        # @param [Hash] options Opção para a criação do boleto.
        # @option options [Symbol] :resolucao Resolução em pixels.
        # @option options [Symbol] :formato Formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        def modelo_generico_multipage(boletos, options = {})
          doc = Document.new paper: :A4 # 210x297

          template_path = File.join(File.dirname(__FILE__), '..', '..', 'arquivos', 'templates', 'modelo_generico.eps')

          fail 'Não foi possível encontrar o template. Verifique o caminho' unless File.exist?(template_path)

          boletos.each_with_index do |boleto, index|
            modelo_generico_template(doc, boleto, template_path)
            modelo_generico_cabecalho(doc, boleto)
            modelo_generico_rodape(doc, boleto)

            # Gerando codigo de barra com rghost_barcode
            doc.barcode_interleaved2of5(boleto.codigo_barras, width: '10.3 cm', height: '1.3 cm', x: "#{@x - 1.7} cm", y: "#{@y - 1.67} cm") if boleto.codigo_barras

            # Cria nova página se não for o último boleto
            doc.next_page unless index == boletos.length - 1
          end
          # Gerando stream
          formato = (options.delete(:formato) || Brcobranca.configuration.formato)
          resolucao = (options.delete(:resolucao) || Brcobranca.configuration.resolucao)
          doc.render_stream(formato.to_sym, resolution: resolucao)
        end

        # Define o template a ser usado no boleto
        def modelo_generico_template(doc, _boleto, template_path)
          doc.define_template(:template, template_path, x: '0.3 cm', y: '0 cm')
          doc.use_template :template

          doc.define_tags do
            tag :grande, size: 13
            tag :maior, size: 15
          end
        end

        def move_more(doc, x, y)
          @x += x
          @y += y
          doc.moveto x: "#{@x} cm", y: "#{@y} cm"
        end
        # Monta o cabeçalho do layout do boleto
        def modelo_generico_cabecalho(doc, boleto)
          # INICIO Primeira parte do BOLETO
          # Pontos iniciais em x e y
          @x = 0.36
          @y = 24.2
          # LOGOTIPO do BANCO
          doc.image boleto.logotipo, x: "#{@x} cm", y: "#{@y} cm"
          # Dados
<<<<<<< HEAD

          move_more(doc, 4.84, 0.03)
          doc.show "#{boleto.banco}-#{boleto.banco_dv}", tag: :maior
          move_more(doc, 2.3, 0)
          doc.show boleto.codigo_barras.linha_digitavel, tag: :grande
          move_more(doc, -6.8, -0.9)

          doc.show boleto.cedente

          move_more(doc, 10.3, 0)
          doc.show boleto.agencia_conta_boleto

          move_more(doc, 3.2, 0)
          doc.show boleto.especie

          move_more(doc, 1.5, 0)
          doc.show boleto.quantidade

          move_more(doc, -15, -0.8)
          doc.show boleto.numero_documento

          move_more(doc, 6.3, 0)
          doc.show "#{boleto.documento_cedente.formata_documento}"

          move_more(doc, 5, 0)
          doc.show boleto.data_vencimento.to_s_br

          move_more(doc, 4.5, 0.8)
          doc.show boleto.nosso_numero_boleto

          move_more(doc, 0, -0.8)
          doc.show boleto.valor_documento.to_currency

          move_more(doc, -15, -1.3)
          doc.show "#{boleto.sacado} - #{boleto.sacado_documento.formata_documento}"

          move_more(doc, 0, -0.3)
=======
          # doc.moveto x: '5.2 cm', y: '23.9 cm'

          move_more(doc, 4.84, 0.03)
          doc.show "#{boleto.banco}-#{boleto.banco_dv}", tag: :maior
          # doc.moveto x: '7.5 cm', y: '23.9 cm'
          move_more(doc, 2.3, 0)
          doc.show boleto.codigo_barras.linha_digitavel, tag: :grande
          # doc.moveto x: '0.7 cm', y: '23.0 cm'
          move_more(doc, -6.8, -0.9)

          doc.show boleto.cedente
          # doc.moveto x: '11 cm', y: '23 cm'
          move_more(doc, 10.3, 0)

          doc.show boleto.agencia_conta_boleto
          # doc.moveto x: '14.2 cm', y: '23 cm'
          move_more(doc, 3.2, 0)

          doc.show boleto.especie
          # doc.moveto x: '15.7 cm', y: '23 cm'
          move_more(doc, 1.5, 0)
          doc.show boleto.quantidade
          # doc.moveto x: '0.7 cm', y: '22.2 cm'
          move_more(doc, -15, -0.8)
          doc.show boleto.numero_documento
          # doc.moveto x: '7 cm', y: '22.2 cm'
          move_more(doc, 6.3, 0)

          doc.show "#{boleto.documento_cedente.formata_documento}"
          # doc.moveto x: '12 cm', y: '22.2 cm'
          move_more(doc, 5, 0)

          doc.show boleto.data_vencimento.to_s_br
          # doc.moveto x: '16.5 cm', y: '23 cm'
          move_more(doc, 4.5, 0.8)

          doc.show boleto.nosso_numero_boleto
          # doc.moveto x: '16.5 cm', y: '22.2 cm'
          move_more(doc, 0, -0.8)

          doc.show boleto.valor_documento.to_currency
          # doc.moveto x: '1.5 cm', y: '20.9 cm'
          move_more(doc, -15, -1.3)

          doc.show "#{boleto.sacado} - #{boleto.sacado_documento.formata_documento}"
          # doc.moveto x: '1.5 cm', y: '20.6 cm'
          move_more(doc, 0, -0.3)

>>>>>>> 088d6f735ed3e6401b7e5b5b9c756ffeb4ad3ef7
          doc.show "#{boleto.sacado_endereco}"
          if boleto.demonstrativo
            doc.text_area boleto.demonstrativo, width: '18.5 cm', text_align: :left, x: "#{@x - 0.8} cm", y: "#{@y - 0.9} cm", row_height: '0.4 cm'
          end
          # FIM Primeira parte do BOLETO
        end

        # Monta o corpo e rodapé do layout do boleto
        def modelo_generico_rodape(doc, boleto)
          # INICIO Segunda parte do BOLETO BB
          # Pontos iniciais em x e y
          @x = 0.36
          @y = 14.27
          # LOGOTIPO do BANCO
          doc.image boleto.logotipo, x: "#{@x} cm", y: "#{@y} cm"
<<<<<<< HEAD

          move_more(doc, 4.84, 0.07)
          doc.show "#{boleto.banco}-#{boleto.banco_dv}", tag: :maior

          move_more(doc, 2.3, 0)
          doc.show boleto.codigo_barras.linha_digitavel, tag: :grande

          move_more(doc, -6.8, -0.9)
          doc.show boleto.local_pagamento

          move_more(doc, 15.8, 0)
          doc.show boleto.data_vencimento.to_s_br if boleto.data_vencimento

          move_more(doc, -15.8, -0.9)
=======
          # doc.moveto x: '5.2 cm', y: '16.9 cm'
          move_more(doc, 4.84, 0.07)

          doc.show "#{boleto.banco}-#{boleto.banco_dv}", tag: :maior
          # doc.moveto x: '7.5 cm', y: '16.9 cm'
          move_more(doc, 2.3, 0)

          doc.show boleto.codigo_barras.linha_digitavel, tag: :grande
          # doc.moveto x: '0.7 cm', y: '16 cm'
          move_more(doc, -6.8, -0.9)

          doc.show boleto.local_pagamento
          # doc.moveto x: '16.5 cm', y: '16 cm'
          move_more(doc, 15.8, 0)

          doc.show boleto.data_vencimento.to_s_br if boleto.data_vencimento
          # doc.moveto x: '0.7 cm', y: '15.2 cm'
          move_more(doc, -15.8, -0.9)

>>>>>>> 088d6f735ed3e6401b7e5b5b9c756ffeb4ad3ef7
          if boleto.cedente_endereco
            # move_more(doc, -15.8, -0.8)
            doc.show boleto.cedente_endereco
<<<<<<< HEAD
            move_more(doc, 1.2, 0.3)
            doc.show boleto.cedente
            move_more(doc, -1.2, -0.3)
          else
            doc.show boleto.cedente
          end

          move_more(doc, 15.8, 0)
          doc.show boleto.agencia_conta_boleto

          move_more(doc, -15.8 , -0.8)
          doc.show boleto.data_documento.to_s_br if boleto.data_documento

          move_more(doc, 3.5, 0)
          doc.show boleto.numero_documento

          move_more(doc, 5.8, 0)
          doc.show boleto.especie_documento

          move_more(doc, 1.7, 0)
          doc.show boleto.aceite

          move_more(doc, 1.3, 0)

          doc.show boleto.data_processamento.to_s_br if boleto.data_processamento

          move_more(doc, 3.5, 0)
          doc.show boleto.nosso_numero_boleto

          move_more(doc, -12.1, -0.8)
=======
            # doc.moveto x: '1.9 cm', y: '15.5 cm'
            move_more(doc, 1.2, 0.3)
            doc.show boleto.cedente
            move_more(doc, -1.2, -0.3)

          else
            doc.show boleto.cedente
          end
          # doc.moveto x: '16.5 cm', y: '15.2 cm'
          move_more(doc, 15.8, 0)

          doc.show boleto.agencia_conta_boleto
          # doc.moveto x: '0.7 cm', y: '14.4 cm'
          move_more(doc, -15.8 , -0.8)

          doc.show boleto.data_documento.to_s_br if boleto.data_documento
          # doc.moveto x: '4.2 cm', y: '14.4 cm'
          move_more(doc, 3.5, 0)

          doc.show boleto.numero_documento
          # doc.moveto x: '10 cm', y: '14.4 cm'
          move_more(doc, 5.8, 0)

          doc.show boleto.especie_documento
          # doc.moveto x: '11.7 cm', y: '14.4 cm'
          move_more(doc, 1.7, 0)

          doc.show boleto.aceite
          # doc.moveto x: '13 cm', y: '14.4 cm'
          move_more(doc, 1.3, 0)

          doc.show boleto.data_processamento.to_s_br if boleto.data_processamento
          # doc.moveto x: '16.5 cm', y: '14.4 cm'
          move_more(doc, 3.5, 0)

          doc.show boleto.nosso_numero_boleto
          # doc.moveto x: '4.4 cm', y: '13.5 cm'
          move_more(doc, -12.1, -0.8)

>>>>>>> 088d6f735ed3e6401b7e5b5b9c756ffeb4ad3ef7
          if boleto.variacao
            doc.show "#{boleto.carteira}-#{boleto.variacao}"
          else
            doc.show boleto.carteira
          end
<<<<<<< HEAD

          move_more(doc, 2, 0)
          doc.show boleto.especie

          move_more(doc, 10.1, 0)
          doc.show boleto.valor_documento.to_currency

          move_more(doc, -15.8, -0.9)
          doc.show boleto.instrucao1

          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao2

          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao3

          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao4

          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao5

          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao6

          move_more(doc, 0.5, -1.9)
          doc.show "#{boleto.sacado} - CPF/CNPJ: #{boleto.sacado_documento.formata_documento}" if boleto.sacado && boleto.sacado_documento

          move_more(doc, 0, -0.4)
          doc.show "#{boleto.sacado_endereco}"

=======
          # doc.moveto x: '6.4 cm', y: '13.5 cm'
          move_more(doc, 2, 0)

          doc.show boleto.especie
          # doc.moveto x: '8 cm', y: '13.5 cm'
          # doc.show boleto.quantidade
          # doc.moveto :x => '11 cm' , :y => '13.5 cm'
          # doc.show boleto.valor.to_currency
          # doc.moveto x: '16.5 cm', y: '13.5 cm'
          move_more(doc, 10.1, 0)

          doc.show boleto.valor_documento.to_currency
          # doc.moveto x: '0.7 cm', y: '12.7 cm'
          move_more(doc, -15.8, -0.9)
          doc.show boleto.instrucao1
          # doc.moveto x: '0.7 cm', y: '12.3 cm'
          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao2
          # doc.moveto x: '0.7 cm', y: '11.9 cm'
          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao3
          # doc.moveto x: '0.7 cm', y: '11.5 cm'
          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao4
          # doc.moveto x: '0.7 cm', y: '11.1 cm'
          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao5
          # doc.moveto x: '0.7 cm', y: '10.7 cm'
          move_more(doc, 0, -0.4)
          doc.show boleto.instrucao6
          # doc.moveto x: '1.2 cm', y: '8.8 cm'
          move_more(doc, 0.5, -1.9)
          doc.show "#{boleto.sacado} - CPF/CNPJ: #{boleto.sacado_documento.formata_documento}" if boleto.sacado && boleto.sacado_documento
          # doc.moveto x: '1.2 cm', y: '8.4 cm'
          move_more(doc, 0, -0.4)
          doc.show "#{boleto.sacado_endereco}"
          # doc.moveto x: '2.4 cm', y: '7.47 cm'
>>>>>>> 088d6f735ed3e6401b7e5b5b9c756ffeb4ad3ef7
          move_more(doc, 1.2, -0.93)
          if boleto.avalista && boleto.avalista_documento
            doc.show "#{boleto.avalista} - #{boleto.avalista_documento}"
          end
          # FIM Segunda parte do BOLETO
        end
      end # Base
    end
  end
end
