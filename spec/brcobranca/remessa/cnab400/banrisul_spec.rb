# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::Banrisul do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 199.9,
      data_vencimento: Date.today,
      numero: 1,
      nosso_numero: 123,
      documento_sacado: '12345678901',
      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
      endereco_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
      bairro_sacado: 'São josé dos quatro apostolos magros',
      cep_sacado: '12345678',
      cidade_sacado: 'Santa rita de cássia maria da silva',
      uf_sacado: 'SP')
  end
  let(:params) do
    {
      carteira: '1',
      agencia: '1102',
      convenio: '9000150',
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      sequencial_remessa: '1',
      pagamentos: [pagamento]
    }
  end

  let(:banrisul) { subject.class.new(params) }

  context 'validacoes dos campos' do
    context '@agencia' do
      it 'deve ser inválido se não possuir uma agência' do
        objeto = subject.class.new(params.merge!(agencia: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Agencia não pode estar em branco.')
      end

      it 'deve ser inválido se a agência tiver mais de 4 dígitos' do
        banrisul.agencia = '12345'
        expect(banrisul.invalid?).to be true
        expect(banrisul.errors.full_messages).to include('Agencia é muito longo (máximo: 4 caracteres).')
      end
    end

    context '@convenio' do
      it 'deve ser inválido se não possuir um convênio' do
        objeto = subject.class.new(params.merge!(convenio: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Convenio não pode estar em branco.')
      end

      it 'deve ser inválido se o convenio tiver mais de 7 dígitos' do
        banrisul.convenio = '12345678'
        expect(banrisul.invalid?).to be true
        expect(banrisul.errors.full_messages).to include('Convenio é muito longo (máximo: 7 caracteres).')
      end
    end

    context '@carteira' do
      it 'deve ser inválido se não possuir uma carteira' do
        objeto = subject.class.new(params.merge!(carteira: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Carteira não pode estar em branco.')
      end

      it 'deve ser inválido se a carteira tiver mais de 1 dígito' do
        banrisul.carteira = '123'
        expect(banrisul.invalid?).to be true
        expect(banrisul.errors.full_messages).to include('Carteira deve ter 1 dígito.')
      end
    end

    context '@sequencial_remessa' do
      it 'deve ser inválido se não possuir um num. sequencial de remessa' do
        objeto = subject.class.new(params.merge!(sequencial_remessa: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Sequencial remessa não pode estar em branco.')
      end

      it 'deve ser inválido se sequencial de remessa tiver mais de 8 dígitos' do
        banrisul.sequencial_remessa = '12345678'
        expect(banrisul.invalid?).to be true
        expect(banrisul.errors.full_messages).to include('Sequencial remessa é muito longo (máximo: 7 caracteres).')
      end
    end
  end

  context 'formatacoes dos valores' do
    it 'código do banco deve ser 041' do
      expect(banrisul.cod_banco).to eq '041'
    end

    it 'nome do banco deve ser BANRISUL com 15 posicoes' do
      nome_banco = banrisul.nome_banco
      expect(nome_banco.size).to eq 15
      expect(nome_banco.strip).to eq 'BANRISUL'
    end

    it 'complemento deve ter 294 caracteres com as informações nas posições corretas' do
      complemento = banrisul.complemento
      expect(complemento.size).to eq 294
    end

    it 'info_conta deve ter 20 posicoes' do
      expect(banrisul.info_conta.size).to eq 20
    end

    it 'identificacao da empresa deve ter as informações nas posicoes corretas' do
      id_empresa = banrisul.identificacao_empresa
      expect(id_empresa[1..3]).to eq '001'         # carteira (com 3 dígitos)
      expect(id_empresa[4..7]).to eq '1102'        # agência
      expect(id_empresa[8..14]).to eq '9000150'    # convênio
      expect(id_empresa[15..16]).to eq '96'        # dígitos do convênio
    end

    it 'calcula o dígito verificador do nosso número' do
      # Calculo do dígito:
      # * multiplicar o nosso número acrescido da carteira a esquerda
      #   pelo modulo 11, com base 7
      #
      # carteira(2) + nosso número(11)
      # => 0 1 0 0 0 0 0 0 0 0 1 2 3
      # x  2 7 6 5 4 3 2 7 6 5 4 3 2
      # =  0 7 0 0 0 0 0 0 0 0 4 6 6 = 23
      # 23/11 = 2 com resto 1
      # quando resto 1 codigo sera P
      #
      expect(banrisul.digito_nosso_numero(123)).to eq 'P'
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab400'

    context 'header' do
      it 'informações devem estar posicionadas corretamente no header' do
        header = banrisul.monta_header
        expect(header[1]).to eq '1'                      # tipo operacao (1 = remessa)
        expect(header[2..8]).to eq 'REMESSA'             # literal da operacao
        expect(header[26..45]).to eq banrisul.info_conta # informações da conta
        expect(header[76..78]).to eq '041'               # codigo do banco
      end
    end

    context 'detalhe' do
      it 'informações devem estar posicionadas corretamente no detalhe' do
        detalhe = banrisul.monta_detalhe pagamento, 1
        expect(detalhe[70..80]).to eq '00000000123'                                  # nosso número
        expect(detalhe[81]).to eq 'P'                                                # dígito nosso número
        expect(detalhe[120..125]).to eq Date.today.strftime('%d%m%y')                # data de vencimento
        expect(detalhe[126..138]).to eq '0000000019990'                              # valor do documento
        expect(detalhe[220..233]).to eq '00012345678901'                             # documento do pagador
        expect(detalhe[234..273]).to eq 'PABLO DIEGO JOSE FRANCISCO DE PAULA JUAN'   # nome do pagador
        expect(detalhe[274..313]).to eq banrisul.formata_endereco_sacado(pagamento)  # endereço do pagador
      end
    end

    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(banrisul.gera_arquivo).to eq(read_remessa('remessa-banrisul-cnab400.rem', banrisul.gera_arquivo)) }
    end
  end
end
