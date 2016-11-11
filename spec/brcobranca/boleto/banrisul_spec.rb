# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Boleto::Banrisul do
  let(:valid_attributes) {{
    valor: 0.0,
    local_pagamento: 'Pagável em qualquer banco até o vencimento',
    cedente: 'Kivanio Barbosa',
    documento_cedente: '12345678912',
    sacado: 'Claudio Pozzebom',
    sacado_documento: '12345678900',
    agencia: '1102',
    conta_corrente: '',
    convenio: '9000150',
    numero: '22832563'
  }}

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
    boleto_novo = described_class.new(valid_attributes)
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
    expect(boleto_novo.conta_corrente).to eql('0614533220')
    expect(boleto_novo.agencia).to eql('1102')
    expect(boleto_novo.convenio).to eql("9000150")
    expect(boleto_novo.numero).to eql('0022832563')
    expect(boleto_novo.carteira).to eql('1')
  end

  it 'Montar código de barras para carteira número 06' do
    valid_attributes[:valor] = 550.0
    valid_attributes[:data_documento] = Date.parse('2000-07-04')
    valid_attributes[:data_vencimento] = Date.parse('2000-07-04')
    boleto_novo = described_class.new(valid_attributes)

    expect(boleto_novo.codigo_barras_segunda_parte).to eql('1172060007589645204030050')
    expect(boleto_novo.codigo_barras).to eql('23795422300002952951172060007589645204030050')
    expect(boleto_novo.codigo_barras.linha_digitavel).to eql('23791.17209 60007.589645 52040.300502 5 42230000295295')
  end

  it 'Não permitir gerar boleto com atributos inválido' do
    boleto_novo = described_class.new
    expect { boleto_novo.codigo_barras }.to raise_error(Brcobranca::BoletoInvalido)
    expect(boleto_novo.errors.count).to eql(3)
  end

  it 'Montar nosso_numero_boleto' do
    boleto_novo = described_class.new(valid_attributes)

    boleto_novo.numero = '525'
    expect(boleto_novo.nosso_numero_boleto).to eql('00000525-66')
    expect(boleto_novo.nosso_numero_dv).to eql('66')

    boleto_novo.numero = '2808'
    expect(boleto_novo.nosso_numero_boleto).to eql('00002808-44')
    expect(boleto_novo.nosso_numero_dv).to eql('44')
  end

  it 'Montar agencia_conta_boleto' do
    boleto_novo = described_class.new(valid_attributes)
    expect(boleto_novo.agencia_conta_boleto).to eql('1102.48/9000150-96')
  end

  describe 'Busca logotipo do banco' do
    it_behaves_like 'busca_logotipo'
  end

  it 'Gerar boleto nos formatos válidos com método to_' do
    valid_attributes[:valor] = 2952.95
    valid_attributes[:data_documento] = Date.parse('2009-04-30')
    valid_attributes[:data_vencimento] = Date.parse('2009-04-30')
    valid_attributes[:numero] = '75896452'
    valid_attributes[:conta_corrente] = '0403005'
    valid_attributes[:agencia] = '1172'
    boleto_novo = described_class.new(valid_attributes)

    %w(pdf jpg tif png).each do |format|
      file_body = boleto_novo.send("to_#{format}".to_sym)
      tmp_file = Tempfile.new('foobar.' << format)
      tmp_file.puts file_body
      tmp_file.close
      expect(File.exist?(tmp_file.path)).to be_truthy
      expect(File.stat(tmp_file.path).zero?).to be_falsey
      expect(File.delete(tmp_file.path)).to eql(1)
      expect(File.exist?(tmp_file.path)).to be_falsey
    end
  end

  it 'Gerar boleto nos formatos válidos' do
    valid_attributes[:valor] = 2952.95
    valid_attributes[:data_documento] = Date.parse('2009-04-30')
    valid_attributes[:data_vencimento] = Date.parse('2009-04-30')
    valid_attributes[:numero] = '75896452'
    valid_attributes[:conta_corrente] = '0403005'
    valid_attributes[:agencia] = '1172'
    boleto_novo = described_class.new(valid_attributes)

    %w(pdf jpg tif png).each do |format|
      file_body = boleto_novo.to(format)
      tmp_file = Tempfile.new('foobar.' << format)
      tmp_file.puts file_body
      tmp_file.close
      expect(File.exist?(tmp_file.path)).to be_truthy
      expect(File.stat(tmp_file.path).zero?).to be_falsey
      expect(File.delete(tmp_file.path)).to eql(1)
      expect(File.exist?(tmp_file.path)).to be_falsey
    end
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

  describe "#conta_corrente_dv" do
    # it { expect(described_class.new(conta_corrente: "0301357").conta_corrente_dv).to eq("P") }
  end
end
