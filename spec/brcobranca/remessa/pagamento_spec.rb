# -*- encoding: utf-8 -*

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Pagamento do
  let(:pagamento) do
    described_class.new(valor: 199.9,
                      data_vencimento: Date.parse('2015-06-25'),
                      nosso_numero: 123,
                      documento_sacado: '12345678901',
                      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
                      logradouro_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva',
                      numero_sacado: '999',
                      bairro_sacado: 'São josé dos quatro apostolos magros',
                      cep_sacado: '12345678',
                      cidade_sacado: 'Santa rita de cássia maria da silva',
                      uf_sacado: 'SP')
  end

  context 'validacoes' do
    it 'deve ser inválido se não possuir nosso numero' do
      pagamento.nosso_numero = nil
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Nosso numero não pode estar em branco.')
    end

    it 'deve ser inválido se não possuir data de vencimento' do
      pagamento.data_vencimento = nil
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Data vencimento não pode estar em branco.')
    end

    it 'deve ser inválido se não possuir valor do documento' do
      pagamento.valor = nil
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Valor não pode estar em branco.')
    end

    it 'deve ser inválido se não possuir documento do sacado' do
      pagamento.documento_sacado = nil
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Documento sacado não pode estar em branco.')
    end

    it 'deve ser inválido se não possuir nome do sacado' do
      pagamento.nome_sacado = nil
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Nome sacado não pode estar em branco.')
    end

    it 'deve ser inválido se não possuir logradouro do sacado' do
      pagamento.logradouro_sacado = nil
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Logradouro sacado não pode estar em branco.')
    end

    describe '#validar_numero_sacado' do
      before { pagamento.numero_sacado = nil }

      context 'ativado' do
        before { pagamento.validar_numero_sacado = true }

        it do
          expect(pagamento.invalid?).to be true
          expect(pagamento.errors.full_messages).to include('Numero sacado não pode estar em branco.')
        end
      end

      context 'desativado' do
        before { pagamento.validar_numero_sacado = false }

        it { expect(pagamento.invalid?).to be false }
      end
    end

    it 'deve ser inválido se não possuir cidade do sacado' do
      pagamento.cidade_sacado = nil
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Cidade sacado não pode estar em branco.')
    end

    it 'deve ser inválido se não possuir UF do sacado' do
      pagamento.uf_sacado = nil
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Uf sacado não pode estar em branco.')
    end

    context '@cep' do
      it 'deve ser inválido se não possuir CEP' do
        pagamento.cep_sacado = nil
        expect(pagamento.invalid?).to be true
        expect(pagamento.errors.full_messages).to include('Cep sacado não pode estar em branco.')
      end

      it 'deve ser inválido se CEP não tiver 8 dígitos' do
        pagamento.cep_sacado = '123456789'
        expect(pagamento.invalid?).to be true
        expect(pagamento.errors.full_messages).to include('Cep sacado deve ter 8 dígitos.')
      end
    end

    it 'deve ser inválido se código do desconto tiver mais de 1 dígito' do
      pagamento.cod_desconto = '123'
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Cod desconto deve ter 1 dígito.')
    end

    it 'deve ser inválido se código do segundo desconto tiver mais de 1 dígito' do
      pagamento.cod_segundo_desconto = '15'
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Cod segundo desconto deve ter 1 dígito.')
    end

    it 'deve ser inválido se código do terceiro desconto tiver mais de 1 dígito' do
      pagamento.cod_terceiro_desconto = '474'
      expect(pagamento.invalid?).to be true
      expect(pagamento.errors.full_messages).to include('Cod terceiro desconto deve ter 1 dígito.')
    end
  end

  context 'informações padrão' do
    it 'data de emissao padrão deve ser o dia corrente' do
      expect(pagamento.data_emissao).to eq Date.current
    end

    it 'nome do avalista padrão deve ser vazio' do
      expect(pagamento.nome_avalista).to eq ''
    end

    it 'valor da mora padrão deve ser zero' do
      expect(pagamento.valor_mora).to eq 0.0
    end

    it 'valor do desconto padrão deve ser zero' do
      expect(pagamento.valor_desconto).to eq 0.0
    end

    it 'valor do IOF padrão deve ser zero' do
      expect(pagamento.valor_iof).to eq 0.0
    end

    it 'valor do abatimento padrão deve ser zero' do
      expect(pagamento.valor_abatimento).to eq 0.0
    end
  end

  context 'formatacoes dos valores' do
    context 'formata data do desconto' do
      it 'formata data limite do desconto de acordo com o formato passado' do
        pagamento.data_desconto = Date.parse('2015-06-25')
        # formato padrão: DDMMAA
        expect(pagamento.formata_data_desconto).to eq '250615'
        # outro formato
        expect(pagamento.formata_data_desconto('%d%m%Y')).to eq '25062015'
      end

      it 'retorna zeros se a data estiver vazia' do
        pagamento.data_desconto = nil
        expect(pagamento.formata_data_desconto).to eq '000000'
      end
    end

    it 'formata valor com o numero de posicoes passadas' do
      # padrão com 13 posicoes
      expect(pagamento.formata_valor).to eq '0000000019990'
      # formata com o numero passado
      expect(pagamento.formata_valor(8)).to eq '00019990'
    end

    it 'formata valor de mora com o numero de posicoes passadas' do
      # padrão com 13 posicoes
      pagamento.valor_mora = 9.0
      expect(pagamento.formata_valor_mora).to eq '0000000000900'
    end

    it 'formata valor de desconto com o numero de posicoes passadas' do
      # padrão com 13 posicoes
      pagamento.valor_desconto = 129.0
      expect(pagamento.formata_valor_desconto).to eq '0000000012900'
      # formata com o numero passado
      expect(pagamento.formata_valor_desconto(5)).to eq '12900'
    end

    it 'formata valor do IOF com o numero de posicoes passadas' do
      # padrão com 13 posicoes
      pagamento.valor_iof = 1.84
      expect(pagamento.formata_valor_iof).to eq '0000000000184'
      # formata com o numero passado
      expect(pagamento.formata_valor_iof(15)).to eq '000000000000184'
    end

    it 'formata valor do abatimento com o numero de posicoes passadas' do
      # padrão com 13 posicoes
      pagamento.valor_abatimento = 34.9
      expect(pagamento.formata_valor_abatimento).to eq '0000000003490'
      # formata com o numero passado
      expect(pagamento.formata_valor_abatimento(10)).to eq '0000003490'
    end

    it 'formata valor dos juros com o numero de posicoes passadas' do
      # padrão com 13 posicoes
      pagamento.valor_mora = 49.2
      expect(pagamento.formata_valor_mora).to eq '0000000004920'
      # formata com o tamanho passado
      expect(pagamento.formata_valor_mora(15)).to eq '000000000004920'
    end

    context 'formata valor do campo documento' do
      before { pagamento.documento = '2345' }

      it 'deve formatar assumindo os valores padrão para os parametros tamanho e caracter' do
        expect(pagamento.formata_documento_ou_numero).to eql '2345'.rjust(25, ' ')
      end

      it 'deve formatar com os parametros tamanho e caracter' do
        expect(pagamento.formata_documento_ou_numero(15, '0')).to eql '2345'.rjust(15, '0')
      end

      it 'deve extrair somente o valor do campo no tamanho informado' do
        pagamento.documento = '12345678901234567890'
        expect(pagamento.formata_documento_ou_numero(15, '0')).to eql '123456789012345'
        expect(pagamento.formata_documento_ou_numero(15, '0').length).to eql 15
      end

      it 'deve remover caracteres especiais ou acentuação' do
        pagamento.documento = 'JOÃO DEve R$ 900.00'
        expect(pagamento.formata_documento_ou_numero).to eql '         JOO DEve R 90000'
        expect(pagamento.formata_documento_ou_numero.length).to eql 25
      end
    end

    context 'identificação sacado' do
      it 'verifica a identificação do sacado (pessoa fisica ou juridica)' do
        # pessoa fisica
        expect(pagamento.identificacao_sacado).to eq '01'
        # pessoa juridica
        pagamento.documento_sacado = '123456789101112'
        expect(pagamento.identificacao_sacado).to eq '02'
        pagamento.documento_sacado = '123456789101112'
        expect(pagamento.identificacao_sacado(false)).to eq '2'
      end
    end

    context 'identificação avalista' do
      it 'verifica a identificação do avalista (pessoa fisica ou juridica)' do
        # pessoa fisica
        pagamento.documento_avalista = '12345678901'
        expect(pagamento.identificacao_avalista).to eq '01'
        # pessoa juridica
        pagamento.documento_avalista = '123456789101112'
        expect(pagamento.identificacao_avalista).to eq '02'
      end

      it 'formata a identificação com o numero de caracteres informados' do
        pagamento.documento_avalista = '12345678901'
        expect(pagamento.identificacao_avalista(false)).to eq '1'
      end
    end
  end

  describe '#endereco_sacado' do
    subject { pagamento.endereco_sacado }

    before do
      pagamento.logradouro_sacado = logradouro_sacado
      pagamento.numero_sacado = numero_sacado
      pagamento.complemento_sacado = complemento_sacado
    end

    context 'com todos os campos informados' do
      let(:logradouro_sacado) { 'Rua dos bobos' }
      let(:numero_sacado) { '0' }
      let(:complemento_sacado) { 'casa muito engraçada' }

      it { is_expected.to eq 'Rua dos bobos, 0, casa muito engraçada' }
    end

    context 'com campos em branco' do
      let(:logradouro_sacado) { 'Wall street' }
      let(:numero_sacado) { '999' }
      let(:complemento_sacado) { '' }

      it { is_expected.to eq 'Wall street, 999' }
    end
  end

  describe "#instrucoes_boleto=" do
    subject! { pagamento.instrucoes_boleto = instrucoes }

    context "com quebras de linhas e espaços" do
      let(:instrucoes) { "A\n   B\nC\t"}

      it { expect(pagamento.instrucoes_boleto).to eq "A B C"}
    end
  end
end
