module Components.Home where

import Prelude

import API.Effects (getArticleFeed, getArticles, getArticlesWithTag)
import API.Types (Article, AuthState(..), MultipleArticles)
import Components.Favorited (doFavoriting)
import Control.Alt ((<|>))
import Data.Foldable (oneOf)
import Data.Tuple.Nested ((/\))
import Date (prettyDate)
import Deku.Attribute ((:=))
import Deku.Control (blank, switcher, text, text_)
import Deku.Core (class Korok, Domable)
import Deku.DOM as D
import Deku.Do (useState, useState')
import Deku.Do as Deku
import Deku.Listeners (click)
import Deku.Pursx (nut, (~~))
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import FRP.Event (AnEvent, Event, fromEvent)
import Type.Proxy (Proxy(..))

data ArticleLoadStatus = ArticlesLoading | ArticlesLoaded MultipleArticles
data TagsLoadStatus = TagsLoading | TagsLoaded { tags :: Array String }

articlePreview :: forall s m lock payload. Korok s m => AnEvent m AuthState -> Article -> Domable m lock payload
articlePreview
  currentUser
  { updatedAt
  , favoritesCount: fcount
  , title
  , description
  , slug
  , favorited
  , author: { image, username }
  } = Deku.do
    setFavoritesCount /\ favoritesCount <- useState fcount
    setFavorited /\ isFavorited <- useState favorited
    let fc = nut (text (show <$> favoritesCount))
    let signedOutButton = oneOf
          [ pure $ D.Class := "text-success btn-sm pull-xs-right"
          , currentUser <#> \cu -> D.Style := case cu of
              SignedIn _ -> "display:none;"
              SignedOut -> ""
          ]
    let signedInButton = oneOf
          [ pure $ D.Class := "btn btn-outline-primary btn-sm pull-xs-right"
          , currentUser <#> \cu -> D.Style := case cu of
              SignedIn _ -> ""
              SignedOut -> "display:none;"
          , doFavoriting currentUser slug isFavorited favoritesCount setFavoritesCount setFavorited
          ]
    articlePreview_ ~~
      { image: pure (D.Src := image)
      , profile1: pure (D.Href := "/#/profile/" <> username)
      , profile2: pure (D.Href := "/#/profile/" <> username)
      , signedOutButton
      , signedInButton
      , href: pure (D.Href := "/#/article/" <> slug)
      , username: nut (text_ username)
      , title: nut (D.h1_ [ text_ title ])
      , description: nut (D.p_ [ text_ description ])
      , date: nut (text_ (prettyDate updatedAt))
      , favoritesCount1: fc
      , favoritesCount2: fc
      }

articlesLoading_ =
  Proxy    :: Proxy
         """
                <div class="article-preview">
                        <h2>Loading...</h2>
                </div>
"""

articlePreview_ =
  Proxy    :: Proxy
         """
                <div class="article-preview">
                    <div class="article-meta">
                        <a ~profile1~ ><img ~image~ /></a>
                        <div class="info">
                            <a ~profile2~ class="author">~username~</a>
                            <span class="date">~date~</span>
                        </div>
                    <div ~signedOutButton~>
                        <i class="ion-heart"></i> ~favoritesCount1~
                    </div>
                    <button ~signedInButton~>
                        <i class="ion-heart"></i> ~favoritesCount2~
                    </button>
                    </div>
                    <a ~href~ class="preview-link">
                        ~title~
                        ~description~
                        <span>Read more...</span>
                    </a>
                </div>
"""

home_ =
  Proxy    :: Proxy
         """<div class="home-page">

    <div class="banner">
        <div class="container">
            <h1 class="logo-font">conduit</h1>
            <p>A place to share your knowledge.</p>
        </div>
    </div>

    <div class="container page">
        <div class="row">

            <div class="col-md-9">
                <div class="feed-toggle">
                    <ul class="nav nav-pills outline-active">
                        <li class="nav-item">
                            <a ~feedAttributes~ >Your Feed</a>
                        </li>
                        <li class="nav-item">
                            <a ~globalAttributes~ >Global Feed</a>
                        </li>
                    </ul>
                </div>

                ~articlePreviews~

            </div>

            <div class="col-md-3">
                <div class="sidebar">
                    <p>Popular Tags</p>

                    ~tags~
                </div>
            </div>

        </div>
    </div>

</div>
"""

data Tab = Global | Feed

home :: forall s m lock payload. Korok s m => Event AuthState -> Event ArticleLoadStatus -> Event TagsLoadStatus -> Domable m lock payload
home currentUser articleLoadStatus tagsLoadStatus = Deku.do
  setArticles /\ articles <- useState'
  setTab /\ tab <- useState Global
  home_ ~~
    { articlePreviews: nut
        ( (fromEvent articleLoadStatus <|> articles) # switcher case _ of
            ArticlesLoading -> loading
            ArticlesLoaded a -> D.div_ (map (articlePreview (fromEvent currentUser)) a.articles)
        )
    , feedAttributes: oneOf
        [ { cu: _, ct: _ } <$> (fromEvent currentUser) <*> tab <#> \{ cu, ct } -> D.Class := "nav-link"
            <>
              ( case cu of
                  SignedIn _ -> ""
                  SignedOut -> " disabled"
              )
            <>
              ( case ct of
                  Feed -> " active"
                  Global -> ""
              )
        , fromEvent currentUser <#> \cu -> D.Style := case cu of
            SignedOut -> ""
            SignedIn _ -> "cursor: pointer;"
        , click $ fromEvent currentUser <#> case _ of
            SignedOut -> pure unit
            SignedIn cu -> setArticles ArticlesLoading *> launchAff_
              do
                liftEffect $ setTab Feed
                getArticleFeed cu.token >>= liftEffect <<< setArticles <<< ArticlesLoaded
        ]
    , globalAttributes: oneOf
        [ tab <#> \ct -> D.Class := "nav-link" <> case ct of
            Feed -> ""
            Global -> " active"
        , pure $ D.Style := "cursor: pointer;"
        , click $ pure $ setArticles ArticlesLoading *> launchAff_
            do
              liftEffect $ setTab Global
              getArticles >>= liftEffect <<< setArticles <<< ArticlesLoaded
        ]
    , tags: nut
        ( fromEvent tagsLoadStatus # switcher case _ of
            TagsLoading -> blank
            TagsLoaded tags -> D.div (oneOf [ pure $ D.Class := "tag-list" ])
              ( map
                  ( \tag -> D.a
                      ( oneOf
                          [ pure $ D.Class := "tag-pill tag-default"
                          , pure $ D.Style := "cursor: pointer;"
                          , click $ pure $ setArticles ArticlesLoading *> launchAff_
                              do
                                getArticlesWithTag tag >>= liftEffect <<< setArticles <<< ArticlesLoaded
                          ]
                      )
                      [ text_ tag ]
                  )
                  tags.tags
              )
        )
    }
  where
  loading :: Domable m lock payload
  loading = articlesLoading_ ~~ {}