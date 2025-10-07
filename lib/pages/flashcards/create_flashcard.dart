// lib/pages/flashcards/create_flashcards.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_application/manager/flashcard_manager.dart';
import 'package:study_application/services/pocketbase_service.dart';

/// ====== DRAFT MODEL ======
class FlashcardDraft {
  String term;
  String definition;
  File? termImage;
  File? defImage;

  FlashcardDraft({
    this.term = '',
    this.definition = '',
    this.termImage,
    this.defImage,
  });

  FlashcardDraft copy() => FlashcardDraft(
        term: term,
        definition: definition,
        termImage: termImage,
        defImage: defImage,
      );

}

/// ====== PAGE 1: LIST DRAFTS ======
class CreateFlashcardsPage extends StatefulWidget {
  const CreateFlashcardsPage({
    super.key,
    required this.manager,
    required this.studySetId,
  });

  /// Inject manager (dựa trên PocketBase service)
  final FlashcardManager manager;
  final String studySetId;

  @override
  State<CreateFlashcardsPage> createState() => _CreateFlashcardsPageState();
}

class _CreateFlashcardsPageState extends State<CreateFlashcardsPage> {
  final _cards = <FlashcardDraft>[
    FlashcardDraft(),
    FlashcardDraft(),
    FlashcardDraft(),
  ];
  final _picker = ImagePicker();
  bool _saving = false;

  Future<void> _pickImage({
    required int index,
    required bool isTerm,
  }) async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      final file = File(x.path);
      if (isTerm) {
        _cards[index].termImage = file;
      } else {
        _cards[index].defImage = file;
      }
    });
  }

  void _addCardAt(int afterIndex) {
    setState(() => _cards.insert(afterIndex + 1, FlashcardDraft()));
  }

  void _removeCard(int index) {
    if (_cards.length == 1) return;
    setState(() => _cards.removeAt(index));
  }

  void _openFullEditor(int index) async {
    final updated = await Navigator.of(context).push<FlashcardDraft>(
      MaterialPageRoute(
        builder: (_) => FullCardEditorPage(
          index: index,
          total: _cards.length,
          draft: _cards[index].copy(),
        ),
      ),
    );
    if (updated != null) {
      setState(() => _cards[index] = updated);
    }
  }

  Future<void> _create() async {
    if (_saving) return;
    setState(() => _saving = true);

    final inputs = _cards
        .where((draft) => draft.term.trim().isNotEmpty && draft.definition.trim().isNotEmpty)
        .map(
          (draft) => FlashcardCreate(
            term: draft.term.trim(),
            definition: draft.definition.trim(),
            termImage: draft.termImage?.path,
            defImage: draft.defImage?.path,
            studySetId: widget.studySetId,
          ),
        )
        .toList();

    if (inputs.isEmpty) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one flashcard.')),
        );
      }
      return;
    }

    try {
      await widget.manager.createMany(inputs);
      if (!mounted) return;
      Navigator.pop(context);
    } on PocketBaseServiceException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create flashcards: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Flashcards',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ask kai – coming soon')),
                  );
                },
                icon: const Icon(Icons.add, color: Color(0xFF7A49FF)),
                label: const Text('Ask kai to make cards'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A6B2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                  elevation: 6,
                  shadowColor: const Color(0xFF00A6B2).withOpacity(.35),
                ),
                onPressed: _saving ? null : _create,
                child: const Text('Create',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [
          ...List.generate(_cards.length, (i) {
            final card = _cards[i];
            return Column(
              children: [
                _CardDraftBlock(
                  index: i,
                  draft: card,
                  onTapEdit: () => _openFullEditor(i),
                  onChangeTerm: (v) => card.term = v,
                  onChangeDef: (v) => card.definition = v,
                  onPickTermImage: () => _pickImage(index: i, isTerm: true),
                  onPickDefImage: () => _pickImage(index: i, isTerm: false),
                  onRemove: () => _removeCard(i),
                ),
                const SizedBox(height: 8),
                _CircleAddButton(onTap: () => _addCardAt(i)),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// ====== PAGE 2: FULL EDITOR ======
class FullCardEditorPage extends StatefulWidget {
  final int index;
  final int total;
  final FlashcardDraft draft;
  const FullCardEditorPage({
    super.key,
    required this.index,
    required this.total,
    required this.draft,
  });

  @override
  State<FullCardEditorPage> createState() => _FullCardEditorPageState();
}

class _FullCardEditorPageState extends State<FullCardEditorPage> {
  late TextEditingController _termC;
  late TextEditingController _defC;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _termC = TextEditingController(text: widget.draft.term);
    _defC = TextEditingController(text: widget.draft.definition);
  }

  Future<void> _pick(bool isTerm) async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      final file = File(x.path);
      if (isTerm) {
        widget.draft.termImage = file;
      } else {
        widget.draft.defImage = file;
      }
    });
  }

  @override
  void dispose() {
    _termC.dispose();
    _defC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.index + 1}/${widget.total}';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(
              context,
              widget.draft
                ..term = _termC.text
                ..definition = _defC.text,
            ),
            icon: const Icon(Icons.check, color: Colors.black87),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _FieldTitle('Enter Term'),
          _SoftBox(
            child: TextField(
              controller: _termC,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Start typing your term here',
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 8),
          _Toolbar(onPickImage: () => _pick(true)),
          const SizedBox(height: 18),
          _FieldTitle('Enter Definition'),
          _SoftBox(
            child: TextField(
              controller: _defC,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Start typing your definition here',
              ),
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 8),
          _Toolbar(onPickImage: () => _pick(false)),
          const SizedBox(height: 20),
          if (widget.draft.termImage != null || widget.draft.defImage != null)
            _ImagesPreview(
              term: widget.draft.termImage,
              def: widget.draft.defImage,
              onRemoveTerm: () => setState(() => widget.draft.termImage = null),
              onRemoveDef: () => setState(() => widget.draft.defImage = null),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ask kai – coming soon')),
            );
          },
          icon: const Icon(Icons.add, color: Color(0xFF7A49FF)),
          label: const Text('Ask kai to create this card'),
        ),
      ),
    );
  }
}

/// ====== SMALL WIDGETS ======

class _CardDraftBlock extends StatelessWidget {
  final int index;
  final FlashcardDraft draft;
  final VoidCallback onPickTermImage;
  final VoidCallback onPickDefImage;
  final ValueChanged<String> onChangeTerm;
  final ValueChanged<String> onChangeDef;
  final VoidCallback onTapEdit;
  final VoidCallback onRemove;

  const _CardDraftBlock({
    required this.index,
    required this.draft,
    required this.onPickTermImage,
    required this.onPickDefImage,
    required this.onChangeTerm,
    required this.onChangeDef,
    required this.onTapEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ImageSlot(file: draft.termImage, onPick: onPickTermImage),
              const SizedBox(width: 12),
              Expanded(
                child: _SoftBox(
                  child: TextField(
                    onChanged: onChangeTerm,
                    controller: TextEditingController(text: draft.term),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Term',
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ImageSlot(file: draft.defImage, onPick: onPickDefImage),
              const SizedBox(width: 12),
              Expanded(
                child: _SoftBox(
                  child: TextField(
                    onChanged: onChangeDef,
                    controller: TextEditingController(text: draft.definition),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Definition',
                    ),
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onTapEdit,
                icon: const Icon(Icons.open_in_full),
                label: const Text('Open editor'),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _ImageSlot extends StatelessWidget {
  final File? file;
  final VoidCallback onPick;

  const _ImageSlot({required this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final child = file == null
        ? const Icon(Icons.image_not_supported_rounded, color: Colors.black45)
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file!, fit: BoxFit.cover),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPick,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE0E5EE),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _SoftBox extends StatelessWidget {
  final Widget child;
  const _SoftBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF3)),
      ),
      child: child,
    );
  }
}

class _FieldTitle extends StatelessWidget {
  final String text;
  const _FieldTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final VoidCallback? onPickImage;
  const _Toolbar({this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SoftIconButton(
          icon: Icons.translate_rounded,
          label: 'Language',
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _SquareIconButton(icon: Icons.image_outlined, onTap: onPickImage),
        const SizedBox(width: 8),
        _SquareIconButton(icon: Icons.mic_none_rounded, onTap: () {}),
        const SizedBox(width: 8),
        _SquareIconButton(icon: Icons.lightbulb_outline, onTap: () {}),
      ],
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SoftIconButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade800),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: Colors.grey.shade800, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SquareIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: Icon(icon, color: Colors.black54),
      ),
    );
  }
}

class _ImagesPreview extends StatelessWidget {
  final File? term;
  final File? def;
  final VoidCallback onRemoveTerm;
  final VoidCallback onRemoveDef;

  const _ImagesPreview({
    required this.term,
    required this.def,
    required this.onRemoveTerm,
    required this.onRemoveDef,
  });

  @override
  Widget build(BuildContext context) {
    if (term == null && def == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Images', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (term != null) _thumb(term!, onRemoveTerm),
            if (def != null) ...[
              if (term != null) const SizedBox(width: 10),
              _thumb(def!, onRemoveDef),
            ],
          ],
        ),
      ],
    );
  }

  Widget _thumb(File file, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.cancel, color: Colors.black54, size: 20),
          ),
        )
      ],
    );
  }
}

class _CircleAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }
}
