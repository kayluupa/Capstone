import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:google_sign_in/google_sign_in.dart';

import 'dart:io';
import '../../../core/widgets/no_internet.dart';
import '/helpers/extensions.dart';
import '/routing/routes.dart';
import '/theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  //Upload image to firebase
  Future<void> _uploadImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child("Profile Pictures")
        .child('${FirebaseAuth.instance.currentUser!.uid}.png');
    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      await storageRef.putFile(imageFile);
      String downloadURL = await storageRef.getDownloadURL();
      await FirebaseAuth.instance.currentUser!.updatePhotoURL(downloadURL);
      setState(() {
        _image = imageFile;
      });
    }
  }

  // Fetch phone number from Firestore
  Future<String?> _fetchPhoneNumber() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.get('phone number').toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meet Me Halfway',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
            },
          ),
        ],
      ),
      body: OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          List<ConnectivityResult> connectivity,
          Widget child,
        ) {
          final bool connected =
              connectivity.contains(ConnectivityResult.mobile) ||
                  connectivity.contains(ConnectivityResult.wifi);

          return connected ? _accountPage(context) : const BuildNoInternet();
        },
        child: _accountPage(
            context),
      ),
    );
  }

  SafeArea _accountPage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.w),
        child: SingleChildScrollView(
          child: FutureBuilder<String?>(
            future: _fetchPhoneNumber(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 124, 33, 243),
                ));
              } else if (snapshot.hasError) {
                return const CircularProgressIndicator();
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Text('-');
              } else {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _uploadImage,
                          child: SizedBox(
                            height: 120,
                            width: 120,
                            child: _image == null
                                ? (FirebaseAuth.instance.currentUser!.photoURL ==
                                        null
                                    ? Image.asset('assets/placeholder.png')
                                    : FadeInImage.assetNetwork(
                                        placeholder: 'assets/placeholder.png',
                                        image: FirebaseAuth
                                            .instance.currentUser!.photoURL!,
                                        fit: BoxFit.cover,
                                      ))
                                : Image.file(_image!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _uploadImage,
                          child: const Text('Change Picture'),
                        ),
                      ],
                    ),
                    const Gap(20),
                    Text(
                      FirebaseAuth.instance.currentUser!.displayName ?? 'No Name',
                      style: TextStyles.font15DarkBlue500Weight
                          .copyWith(fontSize: 30.sp),
                    ),
                    const Gap(10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          FirebaseAuth.instance.currentUser!.email ?? 'No Email',
                          style: TextStyles.font15DarkBlue500Weight,
                        ),
                        const Gap(20),
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          snapshot.data!,
                          style: TextStyles.font15DarkBlue500Weight,
                        ),
                      ],
                    ),
                    const Gap(30),
                    Center(
                      child: SizedBox(
                        height: 50.w,
                        width: 100.w,
                        child: AppTextButton(
                          buttonText: 'Sign Out',
                          textStyle: TextStyles.font15DarkBlue500Weight,
                          onPressed: () async {
                            try {
                              FirebaseAuth.instance.signOut();
                              context.pushNamedAndRemoveUntil(
                                Routes.loginScreen,
                                predicate: (route) => false,
                              );
                            } catch (e) {
                              await AwesomeDialog(
                                context: context,
                                dialogType: DialogType.info,
                                animType: AnimType.rightSlide,
                                title: 'Sign out error',
                                desc: e.toString(),
                              ).show();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
