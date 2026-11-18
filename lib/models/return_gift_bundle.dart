import 'dart:typed_data';
import 'product.dart';

class ReturnGiftBundle {
  ProductModel? selectedBag;
  bool isCustomBag;
  Uint8List? customImageBytes;
  String? customImageFileName;
  String customDesignNotes;
  
  // Items chosen to put inside each bag: Map of productId -> quantity per bag
  final Map<String, int> selectedItems;
  final Map<String, ProductModel> accessoriesMap;
  
  int numberOfBags;
  String customPartyMessage;

  ReturnGiftBundle({
    this.selectedBag,
    this.isCustomBag = false,
    this.customImageBytes,
    this.customImageFileName,
    this.customDesignNotes = '',
    Map<String, int>? selectedItems,
    Map<String, ProductModel>? accessoriesMap,
    this.numberOfBags = 10,
    this.customPartyMessage = '',
  })  : selectedItems = selectedItems ?? {},
        accessoriesMap = accessoriesMap ?? {};

  double get bagPrice => selectedBag?.price ?? 250.0;

  double get accessoriesPerBagTotal {
    double total = 0.0;
    selectedItems.forEach((productId, qty) {
      final product = accessoriesMap[productId];
      if (product != null) {
        total += product.price * qty;
      }
    });
    return total;
  }

  double get pricePerBag => bagPrice + accessoriesPerBagTotal;

  int get totalAccessoriesCount {
    int count = 0;
    selectedItems.forEach((_, qty) => count += qty);
    return count;
  }

  double get rawSubtotal => pricePerBag * numberOfBags;

  int get bulkDiscountPercent {
    if (numberOfBags >= 15) return 10;
    if (numberOfBags >= 10) return 5;
    return 0;
  }

  double get discountAmount => rawSubtotal * (bulkDiscountPercent / 100);

  double get finalTotal => rawSubtotal - discountAmount;

  void toggleItem(ProductModel product) {
    if (selectedItems.containsKey(product.id)) {
      selectedItems.remove(product.id);
      accessoriesMap.remove(product.id);
    } else {
      selectedItems[product.id] = 1;
      accessoriesMap[product.id] = product;
    }
  }

  void updateItemQuantity(String productId, int newQty) {
    if (newQty <= 0) {
      selectedItems.remove(productId);
      accessoriesMap.remove(productId);
    } else {
      selectedItems[productId] = newQty;
    }
  }

  bool isItemSelected(String productId) => selectedItems.containsKey(productId);
  int getItemQuantity(String productId) => selectedItems[productId] ?? 0;
}
