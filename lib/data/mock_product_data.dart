import '../models/care_record.dart';
import '../models/product_space.dart';

final productSpaces = <ProductSpace>[
  const ProductSpace(
    id: 'zone-1',
    name: '주방',
    description: '냉장고, 음식물처리기, 전자레인지, 싱크대',
    productCount: 4,
    identifiedProductCount: 1,
  ),
  const ProductSpace(
    id: 'zone-2',
    name: '거실',
    description: '소파, 공기청정기, TV',
    productCount: 1,
    identifiedProductCount: 0,
  ),
  const ProductSpace(
    id: 'zone-3',
    name: '욕실',
    description: '세면대, 환풍기, 비데',
    productCount: 1,
    identifiedProductCount: 0,
  ),
  const ProductSpace(
    id: 'zone-4',
    name: '침실',
    description: '침대, 매트리스, 가습기',
    productCount: 1,
    identifiedProductCount: 0,
  ),
];

final careRecords = <CareRecord>[
  CareRecord(
    id: 'record-1',
    title: '음식물처리기 관리 완료',
    spaceName: '주방',
    completedAt: DateTime(2026, 6, 5, 8, 30),
    minutes: 18,
    productId: 'food-waste-processor',
  ),
  CareRecord(
    id: 'record-2',
    title: '냉장고 내부 관리 완료',
    spaceName: '주방',
    completedAt: DateTime(2026, 6, 4, 21, 10),
    minutes: 15,
    productId: 'fridge',
  ),
  CareRecord(
    id: 'record-3',
    title: '소파 표면 관리 완료',
    spaceName: '거실',
    completedAt: DateTime(2026, 6, 3, 19, 45),
    minutes: 20,
    productId: 'sofa',
  ),
];
