import 'dart:convert';
// import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:convert';
import 'dart:typed_data';
// import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';


class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late IO.Socket socket;
  List<String> activeUsers = [];
  List<String> videoFileNames = [];
  List<String> videoFilePaths = [];
  List<Uint8List?> filesUploaded = [];
  List<String> queueFileNames = [];
  List<String> queueFilePaths = [];
  List<Uint8List?> queueVideoFiles = [];
  String? currentVideo;
  VideoPlayerController? _controller;
  VideoPlayerController? _controllernext;
  String _videoUrl = "";
  
  bool isUploading = false;
  List<String> items = List.generate(20, (index) => 'Item $index');

  @override
  void initState() {
    super.initState();
    initSocket();
    _initializeVideo("https://your-default-video-url.mp4");
  }

  void _handleIncomingJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey("videoUrl")) {
        final videoUrl = data["videoUrl"] as String;
        _initializeVideo(videoUrl); // Play the new video
        // _saveVideoUrl(videoUrl); // Save the URL for future use
      }
    } catch (e) {
      print("Invalid JSON: $e");
    }
  }

  String getname(){
    return "";
  }

  sendToQueue(Uint8List? bytes,String filename,String filepath){
    queueVideoFiles.add(bytes);
    queueFileNames.add(filename);
    queueFilePaths.add(filepath);
  }

  void _initializeVideo(String videoUrl) {
    _videoUrl = videoUrl;
    _controller?.dispose();
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _controller?.play();
        });
      }).catchError((e) {
        print("Error initializing video: $e");
      });
  }


  void _initializeVideo1() {
    try {
  _controllernext?.dispose();
  // _controllernext = VideoPlayerController.file(filesUploaded[0]);
    _controllernext!.initialize().then((_) {
      setState(() {
        _controllernext?.play();
      });
    }).catchError((e) {
      print("Error initializing video: $e");
    });
} catch (e) {
  // TODO
  print("object");
}
  }

  void initSocket() {
    socket = IO.io('http://localhost:8080/', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to Socket.IO server');
      socket.emit("register", "Justin");
    });

    socket.on('activeUsers', (data) {
      setState(() {
        activeUsers = List<String>.from(data);
      });
    });

    socket.on('newVideoUrl', (data) {
      _handleIncomingJson(data);
      setState(() {
        
      });
    });

    socket.on('disconnect', (_) {
      print('Disconnected from Socket.IO server');
    });
  }

Future<String> uploadBytes(Uint8List? uint8List, String apiUrl,String filename) async {
  try {
    Dio dio = new Dio();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String apiKey = prefs.getString('apiKey') ?? "";
      FormData formData = FormData.fromMap({
        "file":await MultipartFile.fromBytes(uint8List!,filename: filename)
      });
      String baseUrl = prefs.getString('baseUrl') ?? "";
      // dio.options.headers['x-api-key'] = apiKey;
      Response response = await dio.post(apiUrl, data: formData);
      print("object");
    return response.data["url"];
  } catch (e) {
    print('Error uploading file: $e');
    return "";
  }
}

  String generateRandomString(int length) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => characters.codeUnitAt(random.nextInt(characters.length)),
    ),
  );
}

  void pickFile() async {
  try {
    setState(() {
      isUploading = true;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null) {
      // Access the first file's bytes
      for (PlatformFile file in result.files) {
        filesUploaded.add(file.bytes); // Add file bytes to the list
        videoFileNames.add(file.name);
        String filepath=await uploadBytes(file.bytes, "http://localhost:8080/uploadBytes",file.name);

      }

      
      
      setState(() {
        isUploading = false;
      });
    } else {
      print("File selection canceled.");
      setState(() {
        isUploading = false;
      });
    }
  } catch (e) {
    print("Error picking file: $e");
    setState(() {
      isUploading = false;
    });
  }
}



  void showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Video Queue'),
          content: Container(
            // Adjust the height and width of the ListView
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true, // Ensures ListView takes up only needed space
              itemCount: queueVideoFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text((queueFileNames[index])),
                  onTap: () {
                    // Handle item selection
                    Navigator.of(context).pop(); // Close the dialog
                    print('Selected: ${items[index]}');
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    socket.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "DIPSY",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 25,
                    fontFamily: "Sofia",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(child: Container()),
                IconButton(onPressed: (){
                  showPopup(context);
                }, icon: Icon(Icons.list,color: Colors.grey,)),
                IconButton(onPressed: (){

                }, icon: Icon(Icons.logout,color: Colors.grey,))
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Next Video",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _controllernext != null && _controllernext!.value.isInitialized
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AspectRatio(
                                    aspectRatio: _controllernext!.value.aspectRatio,
                                    child: VideoPlayer(_controllernext!),
                                  ),
                                )
                              : Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.redAccent,
                                  ),
                                ),
                          height: 250,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Live TV",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _controller != null && _controller!.value.isInitialized
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AspectRatio(
                                    aspectRatio: _controller!.value.aspectRatio,
                                    child: VideoPlayer(_controller!),
                                  ),
                                )
                              : Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.redAccent,
                                  ),
                                ),
                          height: 250,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          "Online Users",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: activeUsers.isEmpty
                              ? Center(
                                  child: Text(
                                    "No users online",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: activeUsers.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey,
                                      ),
                                      title: Text(
                                        activeUsers[index],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              "File Explorer",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            isUploading
                ? Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  )
                : GestureDetector(
                    onTap: pickFile,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 170,
                      child: filesUploaded.isEmpty
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Upload a File",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: filesUploaded.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (videoFileNames[index]),
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      IconButton(onPressed: (){
                                        sendToQueue(filesUploaded[index],videoFileNames[index],videoFilePaths[index]);
                                        _initializeVideo1();
                                      }, icon: Icon(Icons.queue)),
                                      IconButton(onPressed: (){
                                        socket.emit("updateVideoUrl",'{"videoUrl":${videoFilePaths[index]}}');
                                      }, icon: Icon(Icons.send))
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
