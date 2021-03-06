{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE StandaloneDeriving #-}
module Message
  where

import Protolude
import Data.Aeson (ToJSON, FromJSON)
import Data.Default
import Data.Time.Calendar
import Data.List.NonEmpty (NonEmpty)
import Control.Lens.TH
import Control.Lens
import Reflex.Dom.WebSocket.Message

import Common

-- Messages

type AppRequest
  =
    -- Kanji/Vocab Browser
    KanjiFilter
  :<|> LoadMoreKanjiResults

  :<|> GetKanjiDetails
  :<|> LoadMoreKanjiVocab

  :<|> VocabSearch
  :<|> LoadMoreVocabSearchResult

  :<|> QuickAddSrsItem
  :<|> QuickToggleWakaru

  :<|> GetSrsStats

  -- Doing Review
  :<|> GetNextReviewItems
  :<|> DoReview
  :<|> CheckAnswer

  -- Browsing Srs Items
  :<|> BrowseSrsItems
  :<|> GetSrsItem
  :<|> EditSrsItem
  :<|> BulkEditSrsItems

  :<|> AddOrEditDocument
  :<|> ListDocuments
  :<|> ViewDocument
  :<|> ViewRawDocument
  :<|> DeleteDocument

  :<|> QuickAnalyzeText

  :<|> GetReaderSettings
  :<|> SaveReaderSettings
  :<|> SaveReadingProgress
  -- :<|> CreateT ReaderDocument
  -- :<|> EditT ReaderDocument
  -- :<|> ReadT ReaderDocument
  -- :<|> ListT ReaderDocument
  -- :<|> DeleteT ReaderDocument

  :<|> GetVocabDetails
  :<|> GetVocabSentences

  :<|> ImportSearchFields
  :<|> ImportData

------------------------------------------------------------
-- class CRUD t where
--   data KeyT t
--   data CreateT t
--   createT :: CreateT t -> t
--   readT :: KeyT t -> t
--   updateT :: KeyT t -> t -> ()
--   deleteT :: KeyT t -> ()
--   listT :: [t]

-- instance WebSocketMessage AppRequest (CreateT t) where
--   type ResponseT AppRequest (CreateT t) = (Maybe (KeyT t))

-- instance WebSocketMessage AppRequest (EditT t) where
--   type ResponseT AppRequest (CreateT t) = (Maybe (KeyT t))
----------------------------------------------------------------
data KanjiFilter = KanjiFilter
  { textContent :: Text
  , kanjiAdditionalFilter :: AdditionalFilter
  , selectedRadicals :: [RadicalId]
  }
  deriving (Generic, Show, ToJSON, FromJSON)

instance Default KanjiFilter where
  def = KanjiFilter "" def []

instance WebSocketMessage AppRequest KanjiFilter where
  type ResponseT AppRequest KanjiFilter = KanjiFilterResult

data KanjiFilterResult =
  KanjiFilterResult KanjiList --
                    [RadicalId] -- Valid Radicals
  deriving (Generic, Show, ToJSON, FromJSON)

type KanjiList =
   [(KanjiId, Kanji, Maybe Rank, [Meaning])]

----------------------------------------------------------------
data GetKanjiDetails =
  GetKanjiDetails KanjiId AdditionalFilter
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetKanjiDetails where
  type ResponseT AppRequest GetKanjiDetails = Maybe KanjiSelectionDetails

data VocabSrsState
  = NotInSrs
  | InSrs SrsEntryId
  | IsWakaru
  deriving (Eq, Ord, Generic, Show, ToJSON, FromJSON)

type VocabList = [(VocabDetails, VocabSrsState)]

data KanjiSelectionDetails =
  KanjiSelectionDetails KanjiDetails VocabSrsState VocabList
  deriving (Generic, Show, ToJSON, FromJSON)

data LoadMoreKanjiVocab = LoadMoreKanjiVocab
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest LoadMoreKanjiVocab where
  type ResponseT AppRequest LoadMoreKanjiVocab = VocabList

----------------------------------------------------------------
data LoadMoreKanjiResults = LoadMoreKanjiResults
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest LoadMoreKanjiResults where
  type ResponseT AppRequest LoadMoreKanjiResults = KanjiList

----------------------------------------------------------------
data VocabSearch = VocabSearch Text (Maybe PartOfSpeech)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest VocabSearch where
  type ResponseT AppRequest VocabSearch = VocabList

data LoadMoreVocabSearchResult = LoadMoreVocabSearchResult
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest LoadMoreVocabSearchResult where
  type ResponseT AppRequest LoadMoreVocabSearchResult = VocabList

----------------------------------------------------------------
data QuickAddSrsItem = QuickAddSrsItem (Either KanjiId VocabId)
  (Maybe Text)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest QuickAddSrsItem where
  type ResponseT AppRequest QuickAddSrsItem = VocabSrsState

----------------------------------------------------------------
data QuickToggleWakaru = QuickToggleWakaru (Either KanjiId VocabId)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest QuickToggleWakaru where
  type ResponseT AppRequest QuickToggleWakaru = VocabSrsState

----------------------------------------------------------------

data GetSrsStats = GetSrsStats ()
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetSrsStats where
  type ResponseT AppRequest GetSrsStats =
    (SrsStats, SrsStats)

data SrsStats = SrsStats
  { reviewsToday :: Int
  , totalItems :: Int
  , totalReviews :: Int
  , averageSuccess :: Int
  }
  deriving (Generic, Show, ToJSON, FromJSON)

----------------------------------------------------------------
data BrowseSrsItems = BrowseSrsItems ReviewType BrowseSrsItemsFilter
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest BrowseSrsItems where
  type ResponseT AppRequest BrowseSrsItems = [SrsItem]

data BrowseSrsItemsFilter
  = BrowseDueItems SrsItemLevel
  | BrowseNewItems
  | BrowseSuspItems SrsItemLevel
  | BrowseOtherItems SrsItemLevel
  deriving (Generic, Show, ToJSON, FromJSON)

data SrsItemLevel = LearningLvl | IntermediateLvl | MatureLvl
  deriving (Eq, Ord, Generic, Show, ToJSON, FromJSON)

----------------------------------------------------------------
data GetNextReviewItems =
  GetNextReviewItems ReviewType [SrsEntryId]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetNextReviewItems where
  type ResponseT AppRequest GetNextReviewItems
    = ([ReviewItem], Int) -- Pending reviews

data ReviewItem = ReviewItem
  { _reviewItemId ::  SrsEntryId
  , _reviewItemField :: SrsEntryField
  , _reviewItemMeaning :: (NonEmpty Meaning, Maybe MeaningNotes)
  , _reviewItemReading :: (NonEmpty Reading, Maybe ReadingNotes)
  }
  deriving (Generic, Show, ToJSON, FromJSON)

getReviewItem
  :: (SrsEntryId, SrsEntry)
  -> ReviewItem
getReviewItem (i,s) =
  ReviewItem i (s ^. field) (m,mn) (r,rn)
  where
    m = (s ^. meaning)
    mn = (s ^. meaningNotes)
    r = (s ^. readings)
    rn = (s ^. readingNotes)

data DoReview = DoReview ReviewType [(SrsEntryId, Bool)]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest DoReview where
  type ResponseT AppRequest DoReview
    = Bool

----------------------------------------------------------------
data CheckAnswer =
  CheckAnswer [Reading] [[(Double, Text)]]
  deriving (Generic, Show, ToJSON, FromJSON)

data CheckAnswerResult
  = AnswerCorrect
  | AnswerIncorrect Text
  deriving (Generic, Show, Eq, ToJSON, FromJSON)

instance WebSocketMessage AppRequest CheckAnswer where
  type ResponseT AppRequest CheckAnswer = CheckAnswerResult

----------------------------------------------------------------
data GetSrsItem = GetSrsItem SrsEntryId
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetSrsItem where
  type ResponseT AppRequest GetSrsItem
    = Maybe (SrsEntryId, SrsEntry)

----------------------------------------------------------------
data EditSrsItem = EditSrsItem SrsEntryId SrsEntry
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest EditSrsItem where
  type ResponseT AppRequest EditSrsItem = ()

----------------------------------------------------------------
data BulkEditSrsItems = BulkEditSrsItems ReviewType [SrsEntryId] BulkEditOperation
  deriving (Generic, Show, ToJSON, FromJSON)

data BulkEditOperation
  = SuspendSrsItems
  | MarkDueSrsItems
  | ChangeSrsReviewData Day
  | RemoveFromReviewType
  | AddBothReviewType
  | DeleteSrsItems
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest BulkEditSrsItems where
  type ResponseT AppRequest BulkEditSrsItems = Maybe ()

----------------------------------------------------------------
data AddOrEditDocument =
  AddOrEditDocument (Maybe ReaderDocumentId) Text Text
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest AddOrEditDocument where
  type ResponseT AppRequest AddOrEditDocument
    = (Maybe (ReaderDocumentData))

----------------------------------------------------------------
data ListDocuments = ListDocuments
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ListDocuments where
  type ResponseT AppRequest ListDocuments
    = [(ReaderDocumentId, Text, Text)]

----------------------------------------------------------------
data ViewDocument = ViewDocument ReaderDocumentId (Maybe Int)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ViewDocument where
  type ResponseT AppRequest ViewDocument = (Maybe (ReaderDocumentData))

type ReaderDocumentData =
  (ReaderDocumentId, Text, (Int, Maybe Int), Int
   , [(Int, AnnotatedPara)])

----------------------------------------------------------------
data ViewRawDocument = ViewRawDocument ReaderDocumentId
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ViewRawDocument where
  type ResponseT AppRequest ViewRawDocument = (Maybe (ReaderDocumentId, Text, Text))

----------------------------------------------------------------
data DeleteDocument = DeleteDocument ReaderDocumentId
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest DeleteDocument where
  type ResponseT AppRequest DeleteDocument
    = [(ReaderDocumentId, Text, Text)]

----------------------------------------------------------------
data QuickAnalyzeText = QuickAnalyzeText Text
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest QuickAnalyzeText where
  type ResponseT AppRequest QuickAnalyzeText
    = [(Int, AnnotatedPara)]

----------------------------------------------------------------
data GetReaderSettings = GetReaderSettings
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetReaderSettings where
  type ResponseT AppRequest GetReaderSettings = ReaderSettings CurrentDb

----------------------------------------------------------------
data SaveReaderSettings = SaveReaderSettings (ReaderSettings CurrentDb)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest SaveReaderSettings where
  type ResponseT AppRequest SaveReaderSettings = ()

----------------------------------------------------------------
data SaveReadingProgress = SaveReadingProgress ReaderDocumentId (Int, Maybe Int)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest SaveReadingProgress where
  type ResponseT AppRequest SaveReadingProgress = ()

----------------------------------------------------------------
data GetVocabDetails = GetVocabDetails [VocabId]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetVocabDetails where
  type ResponseT AppRequest GetVocabDetails =
    [(Entry, VocabSrsState)]

----------------------------------------------------------------
data GetVocabSentences = GetVocabSentences (Either VocabId SrsEntryId)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetVocabSentences where
  type ResponseT AppRequest GetVocabSentences =
    ([VocabId], [SentenceData])

----------------------------------------------------------------
data ImportSearchFields = ImportSearchFields [(Int, NonEmpty Text)]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ImportSearchFields where
  type ResponseT AppRequest ImportSearchFields =
    ([(Int, Maybe (Either SrsEntryId (NonEmpty EntryId)))])

data NewEntryUserData = NewEntryUserData
  { mainField :: NonEmpty Text
  , meaningField :: NonEmpty Text
  , readingField :: [Text]
  , readingNotesField :: [Text]
  , meaningNotesField :: [Text]
  }
  deriving (Generic, Show, ToJSON, FromJSON)

data NewEntryOp
  = AddVocabs (NonEmpty VocabId)
  | AddCustomEntry NewEntryUserData [VocabId]
  | MarkWakaru (NonEmpty VocabId)
  deriving (Generic, Show, ToJSON, FromJSON)

data ImportData = ImportData [NewEntryOp]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ImportData where
  type ResponseT AppRequest ImportData = ()

----------------------------------------------------------------
makeLenses ''ReviewItem
