class CreateQualityChecklistRequest {
  const CreateQualityChecklistRequest({
    required this.constructionSiteId,
    required this.name,
    required this.category,
    this.description,
    required this.items,
  });

  final String constructionSiteId;
  final String name;
  final String category;
  final String? description;
  final List<CreateQualityChecklistItem> items;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'name': name,
      'category': category,
      'description': description,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class CreateQualityChecklistItem {
  const CreateQualityChecklistItem({
    required this.sequence,
    required this.requirement,
    required this.isMandatory,
  });

  final int sequence;
  final String requirement;
  final bool isMandatory;

  Map<String, dynamic> toJson() {
    return {
      'sequence': sequence,
      'requirement': requirement,
      'isMandatory': isMandatory,
    };
  }
}