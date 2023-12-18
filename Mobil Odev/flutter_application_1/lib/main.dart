import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kütüphane Otomasyonu',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: KitaplarimPage(),
    );
  }
}

class KitaplarimPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Muhammed Yusuf Erten Kutuphane Yonetimi'),
      ),
      body: KitapListesi(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KitapEklePage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class KitapListesi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('kitaplar').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        List<DocumentSnapshot> documents = snapshot.data!.docs;

        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> kitap =
                documents[index].data() as Map<String, dynamic>;

            return ListTile(
              title: Text(kitap['kitapAdi']),
              subtitle: Text('${kitap['yazar']} - ${kitap['sayfaSayisi']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KitapGuncellePage(
                              kitap: kitap, docId: documents[index].id),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _showDeleteDialog(context, documents[index].id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context, String documentId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Sil'),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('kitaplar')
                    .doc(documentId)
                    .delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class KitapEklePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitap Ekle'),
      ),
      body: KitapEkleForm(),
    );
  }
}

class KitapEkleForm extends StatelessWidget {
  final TextEditingController kitapAdiController = TextEditingController();
  final TextEditingController yayineviController = TextEditingController();
  final TextEditingController yazarController = TextEditingController();
  final TextEditingController sayfaSayisiController = TextEditingController();
  final TextEditingController basimYiliController = TextEditingController();
  bool yayinlanacakMi = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: kitapAdiController,
            decoration: InputDecoration(labelText: 'Kitap Adı'),
          ),
          TextFormField(
            controller: yayineviController,
            decoration: InputDecoration(labelText: 'Yayınevi'),
          ),
          TextFormField(
            controller: yazarController,
            decoration: InputDecoration(labelText: 'Yazar'),
          ),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Kategori'),
            items: ['Roman', 'Tarih', 'Edebiyat', 'Şiir', 'Ansiklopedi']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              // Kategori seçildiğinde yapılacak işlemler
            },
          ),
          TextFormField(
            controller: sayfaSayisiController,
            decoration: InputDecoration(labelText: 'Sayfa Sayısı'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: basimYiliController,
            decoration: InputDecoration(labelText: 'Basım Yılı'),
            keyboardType: TextInputType.number,
          ),
          Row(
            children: [
              Text('Listede yayınlanacak mı?'),
              Checkbox(
                value: yayinlanacakMi,
                onChanged: (bool? value) {
                  // Checkbox değeri değiştiğinde yapılacak işlemler
                },
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              String kitapAdi = kitapAdiController.text;
              String yayinevi = yayineviController.text;
              String yazar = yazarController.text;
              String kategori = ''; // Kategori seçimini almak için kullanılacak
              int sayfaSayisi = int.tryParse(sayfaSayisiController.text) ?? 0;
              int basimYili = int.tryParse(basimYiliController.text) ?? 0;

              if (kitapAdi.isNotEmpty &&
                  yayinevi.isNotEmpty &&
                  yazar.isNotEmpty &&
                  sayfaSayisi > 0 &&
                  basimYili > 0) {
                _ekleFirestore(kitapAdi, yayinevi, yazar, kategori, sayfaSayisi,
                    basimYili);
                Navigator.pop(context);
              } else {
                // Eksik veya hatalı giriş uyarısı
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _ekleFirestore(String kitapAdi, String yayinevi, String yazar,
      String kategori, int sayfaSayisi, int basimYili) {
    FirebaseFirestore.instance.collection('kitaplar').add({
      'kitapAdi': kitapAdi,
      'yayinevi': yayinevi,
      'yazar': yazar,
      'kategori': kategori,
      'sayfaSayisi': sayfaSayisi,
      'basimYili': basimYili,
      'yayinlanacakMi': yayinlanacakMi,
    });
  }
}

class KitapGuncellePage extends StatelessWidget {
  final Map<String, dynamic> kitap;
  final String docId;

  const KitapGuncellePage({required this.kitap, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitap Güncelle'),
      ),
      body: KitapGuncelleForm(kitap: kitap, docId: docId),
    );
  }
}

class KitapGuncelleForm extends StatelessWidget {
  final Map<String, dynamic> kitap;
  final String docId;
  final TextEditingController kitapAdiController;
  final TextEditingController yayineviController;
  final TextEditingController yazarController;
  final TextEditingController sayfaSayisiController;
  final TextEditingController basimYiliController;
  bool yayinlanacakMi = false;

  KitapGuncelleForm({
    required this.kitap,
    required this.docId,
  })  : kitapAdiController = TextEditingController(text: kitap['kitapAdi']),
        yayineviController = TextEditingController(text: kitap['yayinevi']),
        yazarController = TextEditingController(text: kitap['yazar']),
        sayfaSayisiController =
            TextEditingController(text: kitap['sayfaSayisi'].toString()),
        basimYiliController =
            TextEditingController(text: kitap['basimYili'].toString());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: kitapAdiController,
            decoration: InputDecoration(labelText: 'Kitap Adı'),
          ),
          TextFormField(
            controller: yayineviController,
            decoration: InputDecoration(labelText: 'Yayınevi'),
          ),
          TextFormField(
            controller: yazarController,
            decoration: InputDecoration(labelText: 'Yazar'),
          ),
          TextFormField(
            controller: sayfaSayisiController,
            decoration: InputDecoration(labelText: 'Sayfa Sayısı'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: basimYiliController,
            decoration: InputDecoration(labelText: 'Basım Yılı'),
            keyboardType: TextInputType.number,
          ),
          Row(
            children: [
              Text('Listede yayınlanacak mı?'),
              Checkbox(
                value: yayinlanacakMi,
                onChanged: (bool? value) {
                  // Checkbox değeri değiştiğinde yapılacak işlemler
                },
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              String updatedKitapAdi = kitapAdiController.text;
              String updatedYayinevi = yayineviController.text;
              String updatedYazar = yazarController.text;
              int updatedSayfaSayisi =
                  int.tryParse(sayfaSayisiController.text) ?? 0;
              int updatedBasimYili =
                  int.tryParse(basimYiliController.text) ?? 0;

              _guncelleFirestore(updatedKitapAdi, updatedYayinevi, updatedYazar,
                  updatedSayfaSayisi, updatedBasimYili);
              Navigator.pop(context);
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _guncelleFirestore(String updatedKitapAdi, String updatedYayinevi,
      String updatedYazar, int updatedSayfaSayisi, int updatedBasimYili) {
    FirebaseFirestore.instance.collection('kitaplar').doc(docId).update({
      'kitapAdi': updatedKitapAdi,
      'yayinevi': updatedYayinevi,
      'yazar': updatedYazar,
      'sayfaSayisi': updatedSayfaSayisi,
      'basimYili': updatedBasimYili,
      'yayinlanacakMi': yayinlanacakMi,
    });
  }
}
