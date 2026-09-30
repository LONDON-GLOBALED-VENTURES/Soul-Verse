package com.londonglobaledventures.soulverse

import androidx.core.content.FileProvider

// Own subclass so it doesn't clash with other plugins' FileProvider declarations.
class VerseShareFileProvider : FileProvider()
