# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Boleto::Banrisul do
  before do
    @valid_attributes = {
      valor: 0.0,
      local_pagamento: 'Pagável em qualquer banco até o vencimento',
      cedente: 'Kivanio Barbosa',
      documento_cedente: '12345678912',
      sacado: 'Claudio Pozzebom',
      sacado_documento: '12345678900',
      agencia: '1102',
      conta_corrente: '',
      convenio: '1102900015046',
      numero: '22832563'
    }
  end

  it 'Criar nova instancia com atributos padrões' do
    boleto_novo = described_class.new
    expect(boleto_novo.banco).to eql('041')
    expect(boleto_novo.especie_documento).to eql('DM')
    expect(boleto_novo.especie).to eql('R$')
    expect(boleto_novo.moeda).to eql('9')
    expect(boleto_novo.data_documento).to eql(Date.today)
    expect(boleto_novo.data_vencimento).to eql(Date.today)
    expect(boleto_novo.aceite).to eql('S')
    expect(boleto_novo.quantidade).to eql(1)
    expect(boleto_novo.valor).to eql(0.0)
    expect(boleto_novo.valor_documento).to eql(0.0)
    expect(boleto_novo.local_pagamento).to eql('Pagável em qualquer banco até o vencimento')
    expect(boleto_novo.carteira).to eql('1')
  end

  it 'Criar nova instancia com atributos válidos' do
    boleto_novo = described_class.new(@valid_attributes)
    expect(boleto_novo.banco).to eql('041')
    expect(boleto_novo.especie_documento).to eql('DM')
    expect(boleto_novo.especie).to eql('R$')
    expect(boleto_novo.moeda).to eql('9')
    expect(boleto_novo.data_documento).to eql(Date.today)
    expect(boleto_novo.data_vencimento).to eql(Date.today)
    expect(boleto_novo.aceite).to eql('S')
    expect(boleto_novo.quantidade).to eql(1)
    expect(boleto_novo.valor).to eql(0.0)
    expect(boleto_novo.valor_documento).to eql(0.0)
    expect(boleto_novo.local_pagamento).to eql('Pagável em qualquer banco até o vencimento')
    expect(boleto_novo.cedente).to eql('Kivanio Barbosa')
    expect(boleto_novo.documento_cedente).to eql('12345678912')
    expect(boleto_novo.sacado).to eql('Claudio Pozzebom')
    expect(boleto_novo.sacado_documento).to eql('12345678900')
    expect(boleto_novo.convenio).to eql('9000150')
    expect(boleto_novo.agencia).to eql('1102')
    expect(boleto_novo.convenio).to eql("9000150")
    expect(boleto_novo.numero).to eql('22832563')
    expect(boleto_novo.carteira).to eql('1')
  end

  it 'Montar código de barras' do
    @valid_attributes[:valor] = 550.0
    @valid_attributes[:data_documento] = Date.parse('2000-07-04')
    @valid_attributes[:data_vencimento] = Date.parse('2000-07-04')
    boleto_novo = described_class.new(@valid_attributes)

    expect(boleto_novo.codigo_barras_segunda_parte).to eql('2111029000150228325634059')
    expect(boleto_novo.codigo_barras).to eql('04198100100000550002111029000150228325634059')
    expect(boleto_novo.codigo_barras.linha_digitavel).to eql('04192.11107 29000.150226 83256.340593 8 10010000055000')
  end

  it 'Não permitir gerar boleto com atributos inválido' do
    boleto_novo = described_class.new
    expect { boleto_novo.codigo_barras }.to raise_error(Brcobranca::BoletoInvalido)
    expect(boleto_novo.errors.count).to eql(3)
  end

  it 'Montar nosso_numero_boleto' do
    boleto_novo = described_class.new(@valid_attributes)

    boleto_novo.numero = '525'
    expect(boleto_novo.nosso_numero_boleto).to eql('00000525-66')
    expect(boleto_novo.nosso_numero_dv).to eql('66')

    boleto_novo.numero = '2808'
    expect(boleto_novo.nosso_numero_boleto).to eql('00002808-44')
    expect(boleto_novo.nosso_numero_dv).to eql('44')
  end

  it 'Montar agencia_conta_boleto' do
    boleto_novo = described_class.new(@valid_attributes)
    expect(boleto_novo.agencia_conta_boleto).to eql('1102.48 / 9000150-46')
  end

  it 'Extrair o convênio quando 12 ou 13 caracteres' do
    boleto_novo = described_class.new(@valid_attributes)

    boleto_novo.convenio = '456154346054'
    expect(boleto_novo.convenio).to eql('1543460')

    boleto_novo.convenio = '3456154346054'
    expect(boleto_novo.convenio).to eql('1543460')
  end

  describe "#agencia_dv" do
    it { expect(described_class.new(agencia: "0567").agencia_dv).to eq("82") }
    it { expect(described_class.new(agencia: "0085").agencia_dv).to eq("16") }
    it { expect(described_class.new(agencia: "0100").agencia_dv).to eq("81") }
    it { expect(described_class.new(agencia: "1015").agencia_dv).to eq("75") }
    it { expect(described_class.new(agencia: "0028").agencia_dv).to eq("28") }
    it { expect(described_class.new(agencia: "0831").agencia_dv).to eq("86") }
    it { expect(described_class.new(agencia: "0843").agencia_dv).to eq("36") }
    it { expect(described_class.new(agencia: "0025").agencia_dv).to eq("77") }
    it { expect(described_class.new(agencia: "1004").agencia_dv).to eq("12") }
    it { expect(described_class.new(agencia: "0156").agencia_dv).to eq("01") }
    it { expect(described_class.new(agencia: "0039").agencia_dv).to eq("80") }
  end

  describe "#convenio_dv" do
    it { expect(described_class.new(convenio: "1102900015046").convenio_dv).to eq("46") }
    it { expect(described_class.new(convenio: "1102850341060").convenio_dv).to eq("60") }
    it { expect(described_class.new(convenio: "1102855754053").convenio_dv).to eq("53") }
  end

  describe "#nosso_numero_dv" do
    it { expect(described_class.new(numero: "22832563").nosso_numero_dv).to eq("51") }
    it { expect(described_class.new(numero: "84736").nosso_numero_dv).to eq("84") }
    it { expect(described_class.new(numero: "00649").nosso_numero_dv).to eq("47") }
  end

  describe 'Busca logotipo do banco' do
    it_behaves_like 'busca_logotipo'
  end

  describe 'Formato do boleto' do
    before do
      @valid_attributes[:valor] = 2952.95
      @valid_attributes[:data_documento] = Date.parse('2009-04-30')
      @valid_attributes[:data_vencimento] = Date.parse('2009-04-30')
      @valid_attributes[:numero] = '75896452'
      @valid_attributes[:agencia] = '1102'
      @valid_attributes[:convenio] = '1102900015046'
    end

    it_behaves_like 'formatos_validos'
  end
end
