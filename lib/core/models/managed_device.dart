class ManagedDevice {
  final String id;
  final String name;
  final String platform;
  final String osVersion;
  final String? serialNumber;
  final String? imei;
  final String? meid;
  final DateTime? lastSeen;
  final bool isManaged;
  final bool isCompliant;
  final String? policyId;
  final Map<String, dynamic>? additionalData;

  const ManagedDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.osVersion,
    this.serialNumber,
    this.imei,
    this.meid,
    this.lastSeen,
    this.isManaged = true,
    this.isCompliant = true,
    this.policyId,
    this.additionalData,
  });

  factory ManagedDevice.fromJson(Map<String, dynamic> json) {
    return ManagedDevice(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown Device',
      platform: json['platform'] as String? ?? 'Unknown',
      osVersion: json['osVersion'] as String? ?? 'Unknown',
      serialNumber: json['serialNumber'] as String?,
      imei: json['imei'] as String?,
      meid: json['meid'] as String?,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.tryParse(json['lastSeen'].toString()) 
          : null,
      isManaged: json['isManaged'] as bool? ?? true,
      isCompliant: json['isCompliant'] as bool? ?? true,
      policyId: json['policyId'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'osVersion': osVersion,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (imei != null) 'imei': imei,
      if (meid != null) 'meid': meid,
      if (lastSeen != null) 'lastSeen': lastSeen?.toIso8601String(),
      'isManaged': isManaged,
      'isCompliant': isCompliant,
      if (policyId != null) 'policyId': policyId,
      if (additionalData != null) ...additionalData!,
    };
  }

  ManagedDevice copyWith({
    String? id,
    String? name,
    String? platform,
    String? osVersion,
    String? serialNumber,
    String? imei,
    String? meid,
    DateTime? lastSeen,
    bool? isManaged,
    bool? isCompliant,
    String? policyId,
    Map<String, dynamic>? additionalData,
  }) {
    return ManagedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      serialNumber: serialNumber ?? this.serialNumber,
      imei: imei ?? this.imei,
      meid: meid ?? this.meid,
      lastSeen: lastSeen ?? this.lastSeen,
      isManaged: isManaged ?? this.isManaged,
      isCompliant: isCompliant ?? this.isCompliant,
      policyId: policyId ?? this.policyId,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'ManagedDevice(id: $id, name: $name, platform: $platform, osVersion: $osVersion)';
  }
}
