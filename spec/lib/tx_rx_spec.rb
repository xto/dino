require 'spec_helper'

module Dino
  describe TxRx do
    it { should be }

    describe '#initialize' do
      it 'should set first_write to false' do
        TxRx.new.instance_variable_get(:@first_write).should == true
      end
    end

    describe '#io' do
      it 'should instantiate a new SerialPort for each usb tty device found' do
        subject.should_receive(:tty_devices).and_return(['cu.usb', 'tty1.usb', 'tty2.usb'])
        SerialPort.should_receive(:new).with('/dev/tty1.usb', TxRx::BAUD).and_return(mock_serial = mock)
        SerialPort.should_receive(:new).with('/dev/tty2.usb', TxRx::BAUD).and_return(mock)

        subject.io.should == mock_serial
      end

      it 'should use the existing io instance if set' do
        subject.should_not_receive(:tty_devices)
        SerialPort.stub(:new).and_return(mock_serial = mock)

        subject.io = '/dev/tty1.usb'
        subject.io.should == mock_serial
      end

      it 'should raise a BoardNotFound exception if there is no board connected' do
        SerialPort.stub(:new).and_raise
        expect { subject.io }.to raise_exception BoardNotFound
      end
    end

    describe '#io=' do
      it 'should set io to a new serial port with the specified device' do
        SerialPort.should_receive(:new).with('/dev/tty1.usb', TxRx::BAUD).and_return(mock_serial = mock)
        subject.io = '/dev/tty1.usb'
        subject.instance_variable_get(:@io).should == mock_serial
      end
    end

    describe '#read' do
      it 'should create a new thread' do
        Thread.should_receive :new
        subject.read
      end

      it 'should get messages from the device' do
        subject.stub(:io).and_return(mock_serial = mock)

        IO.should_receive(:select).and_return(true)
        Thread.should_receive(:new).and_yield
        subject.should_receive(:loop).and_yield
        mock_serial.should_receive(:gets).and_return("foo::bar\n")
        subject.should_receive(:changed).and_return(true)
        subject.should_receive(:notify_observers).with('foo','bar')

        subject.read
      end
    end

    describe '#close_read' do
      it 'should kill the reading thread' do
        subject.instance_variable_set(:@thread, mock_thread = mock)
        Thread.should_receive(:kill).with(mock_thread)
        subject.read
        subject.close_read
      end
    end

    describe '#write' do
      it 'should write to the device' do
        IO.should_receive(:select).and_return(true)

        subject.stub(:io).and_return(mock_serial = mock)
        mock_serial.should_receive(:puts).with('a message')
        subject.write('a message')
      end
    end
  end
end
