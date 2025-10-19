class TrainingVideo {
  final int id;
  final String videoTitle;
  final String videoDescription;
  final String videoDuration; // swagger shows "45" as a string
  final String videoUrl;

  const TrainingVideo({
    required this.id,
    required this.videoTitle,
    required this.videoDescription,
    required this.videoDuration,
    required this.videoUrl,
  });

  factory TrainingVideo.fromJson(Map<String, dynamic> json) => TrainingVideo(
        id: (json['id'] ?? 0) is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        videoTitle: json['videoTitle']?.toString() ?? '',
        videoDescription: json['videoDescription']?.toString() ?? '',
        videoDuration: json['videoDuration']?.toString() ?? '',
        videoUrl: json['videoUrl']?.toString() ?? '',
      );
}
