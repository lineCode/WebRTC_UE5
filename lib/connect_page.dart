import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:web_socket_channel/web_socket_channel.dart';
class NewConnectPage extends StatefulWidget {
  const NewConnectPage({Key? key}) : super(key: key);

  @override
  State<NewConnectPage> createState() => _NewConnectPageState();
}
const ANSWER_EVENT = 'answer';
const OFFER_EVENT = 'offer';
const ICE_CANDIDATE_EVENT = 'ice-candidate';
typedef void OnOpenCallback();
IO.Socket? socket;
OnOpenCallback? onOpen;
RTCPeerConnection? peerConnection;
final pc = peerConnection;
var _remoteCandidates = [];
final channel = WebSocketChannel.connect(Uri.parse('ws://10.0.0.28'));
class _NewConnectPageState extends State<NewConnectPage> {
	@override
	Widget build(BuildContext context) {
		return Center(
			child: Container(
				color: Colors.yellow,
				child: Column(
					children: [
						ElevatedButton(onPressed: () async {
							channel.stream.listen((data) async {
								data = jsonDecode(data);
								print(data.runtimeType);

								var tag = data['type'];
								onMessage(tag, data);
							}, onError: (error) => print(error),
							);
							// 	socket = IO.io(url,<String, dynamic>{
							// 		'transports' : ['websocket']
							// 	});
							// 	socket!.on('connect', (_){
							// 		print('connected');
							// 		onOpen!;
							// 	});
							// 	socket!.on('exception', (e) => print('Exception: $e'));
							// 	socket!.on('connect_error', (e) => print('Connect error: $e'));
							// 	socket!.on('disconnect', (e)
							// 	{
							// 		print('disconnect');
							// 	});
							// //	socket!.on('message', (e) => print('Message $e'));
							// 	socket!.on('message', handleMessage);
							// 	//TODO :Сюда коннект
						}, child: Text('Call'))
					],
				),
			),
		);
	}

	_send(event, data) {
		channel.sink.add(event,);
	}

	handleMessage(data) {
		print(data);
	}

	_createAnswer(RTCPeerConnection pc) async {
		RTCSessionDescription answer = await pc.createAnswer();
		pc.setLocalDescription(answer);

		final descriprtion = {answer.sdp, answer.type};
		emitAnswerEvent(descriprtion);
	}

	emitAnswerEvent(description) {
		_send(ANSWER_EVENT, {'description': description});
	}

	_createPeerConnection(pc) {
		peerConnection = pc;
	}

	void onMessage(tag, message) async {
		switch (tag) {
			case OFFER_EVENT:
				{
					var pc = await _createPeerConnection(peerConnection);
					peerConnection = pc;
					await pc.setRemoteDescription(
						RTCSessionDescription(message['sdp'],message['type']));
					await _createAnswer(pc);
					if (_remoteCandidates.length > 0) {
						_remoteCandidates.forEach((candidate) async {
							await pc.addCandidate(candidate);
						});
						_remoteCandidates.clear();
					}
				}
				break;
			case ANSWER_EVENT:
				{
					var pc = peerConnection;
					if (pc != null) {
						await pc.setRemoteDescription(
							RTCSessionDescription(message['sdp'], message['type']));
					}
				}
				break;
			case ICE_CANDIDATE_EVENT:
				{
					var candidateMap = message;
					if (candidateMap != null) {
						var pc = peerConnection;
						RTCIceCandidate candidate = RTCIceCandidate(
							candidateMap['candidate'],
							candidateMap['sdpMid'],
							candidateMap['sdpMLineIndex']);
						if (pc != null) {
							await pc.addCandidate(candidate);
						} else {
							_remoteCandidates.add(candidate);
						}
					}
				}
				break;
		}
	}
}
