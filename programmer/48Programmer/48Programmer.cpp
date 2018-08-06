#define ACK 0x06
#define NAK 0x15

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "SerialPort.h"

void burn(SerialPort *programmer, FILE *source) {
	fseek(source, 0, SEEK_END);
	uint16_t firmwareSize = ftell(source);
	rewind(source);

	programmer->writeSerialPort((char *)"burn\n", 5);

	char *recChar = new char[1];
	while (*recChar != '\n') { //wait OK
		if (programmer->readSerialPort(recChar, 1) > 0) {
			std::cout << *recChar;
		}
	}

	programmer->writeSerialPort(firmwareSize & 0xFF);
	programmer->writeSerialPort((firmwareSize >> 8) & 0xFF);
	while (programmer->readSerialPort(recChar, 1) == 0); //wait ACK

	uint8_t readByte;
	uint16_t step = 0;
	while (fread(&readByte, 1, 1, source) != 0) {
		programmer->writeSerialPort(readByte);
		while (programmer->readSerialPort(recChar, 1) == 0);
		if (*recChar == NAK) {
			std::cout << "Burn error on step " << step << '\n';
			std::cin.get();
			exit(0);
		} else
		if (*recChar == ACK) {
			std::cout << "\r" << (int)(step / (double)firmwareSize * 100) << "%";
		} else std::cout << recChar;
		step++;
	}
	std::cout << "\rFinish";
}

void read(SerialPort *programmer, char* fileName, int count) {
	programmer->writeSerialPort((char *)"read\n", 5);

	char incomingData[MAX_DATA_LENGTH] = {0};
	while (incomingData[0] != '\n') { //wait OK
		if (programmer->readSerialPort(incomingData, 1) > 0) {
			std::cout << incomingData[0];
		}
	}

	programmer->writeSerialPort(count & 0xFF);
	programmer->writeSerialPort((count >> 8) & 0xFF);
	while (programmer->readSerialPort(incomingData, 1) == 0); //wait ACK

	char recChar;
	while (strcmp(incomingData, "OK\r\n") != 0) {
		recChar = 0;
		incomingData[0] = 0;
		while (recChar != '\n') { //wait \n
			if (programmer->readSerialPort(&recChar, 1) > 0) {
				strncat(incomingData, &recChar, 1);
			}
		}
		std::cout << incomingData;
	}
}

int main(int argc, char *argv[]) {
	if (argc <= 1) {
		printf("syntax : \n\t -p port - port name \n\t -s baudrate - baud rate \n\t -r [file] - read firmware \n\t -b file - burn firmware\n");
		return 0;
	}

	int boudRate = 9600;
	int operation = -1;
	char *fileName = new char[1];
	char *portName = new char[13];
	strcpy(portName, "\\\\.\\COM30");

	char *opts = (char *)"p:s:rb:";
	int opt;
	while ((opt = getopt(argc, argv, opts)) != -1) {
		switch (opt) {
		case 'p': 
			strncpy(portName+4, optarg, 5);
			break;
		case 's': 
			boudRate = atoi(optarg);
			break;
		case 'r':
			operation = 1;
			break;
		case 'b':
			operation = 2;
			if (optarg != NULL) {
				fileName = new char[strlen(optarg)];
				fileName = optarg;
			}
			break;
		}
	}

	std::cout << "Connect to programmer on port " << portName << " with " << boudRate << " boud rate...\n";

	SerialPort *programmer = new SerialPort(portName, boudRate);
	if (programmer->isConnected()) {
		std::cout << "Connection Established\n";
	} else {
		std::cout << "ERROR, check port name\n";
	}

	programmer->writeSerialPort((char *)"start\n", 6);

	char recChar = 0;
	while (recChar != '\n') { //wait hello
		if (programmer->readSerialPort(&recChar, 1) > 0) {
			std::cout << recChar;
		}
	}

	switch (operation) {
		case 1:
			read(programmer, NULL, 100);
			break;
		case 2:
			FILE *source;
			if (fileName == NULL || (source = fopen(fileName, "rb")) == NULL) {
				printf("Could not open source file: %s\n", argv[1]);
				return 0;
			}
			burn(programmer, source);
			fclose(source);
			break;
	}

	programmer->~SerialPort();
	std::cin.get();
	return 0;
}

