import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class HfDatasetInfo {
  final String datasetId;

  HfDatasetInfo(this.datasetId);
}

class HfDatasetInfoService {
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;
  // let me define a function real quick
  // returns: a map: string : auto

  Future<Map<String, dynamic>> retrieveHfDatasetMetadata(
    String datasetId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/retrieve-dataset?dataset_id=$datasetId'),
      );
      if (response.statusCode == 200) {
        // this would work 100% of the time sure shot
        Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        if (kDebugMode) {
          debugPrint('Idk, here\'s the error code: ${response.statusCode}');
        }
        return {'Error': response.body};
        // idk whatever happened, only triggered when there is some issues with the hf api
      }
    } catch (e) {
      // in case i am using the local backend and I haven't started it
      return {'Error': e.toString()};
    }
  }
}
