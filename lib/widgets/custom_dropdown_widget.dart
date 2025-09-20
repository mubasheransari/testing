import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final void Function(dynamic val) onChanged;
  final List<DropdownMenuItem<dynamic>>? items;
  final String hint;
  final dynamic value;
  final double? fontsize;

  CustomDropdown({required this.hint, required this.onChanged, required this.items, this.value, this.fontsize,
  });

  @override
  Widget build(BuildContext context) {
    return 
    Container(
      decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(5)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: 
      DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          isExpanded: true,
          hint: Text("\t$hint",style: TextStyle(color: Colors.black,fontSize: fontsize,),),
          value: value,
          borderRadius: BorderRadius.circular(8),
          elevation: 0,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.black,
          items: items,
          onChanged: onChanged,
          menuMaxHeight: MediaQuery.of(context).size.height/2,
          dropdownColor: const Color(0xFFD9D9D9),
          enableFeedback: true,
        ),
     ),
    );
  }
}
