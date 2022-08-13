module Components.Profile where


import Prelude

import API.Types (AuthState, SingleProfile, MultipleArticles)
import Data.Maybe (maybe)
import Deku.Attribute ((:=))
import Deku.Control (blank, text_)
import Deku.Core (class Korok, Domable, Nut)
import Deku.DOM as D
import Deku.Pursx (nut, (~~))
import FRP.Event (AnEvent)
import Type.Proxy (Proxy(..))

data ProfileStatus = ProfileLoading | ProfileLoaded SingleProfile MultipleArticles MultipleArticles


profile_ =
  Proxy :: Proxy """<div class="profile-page">

    <div class="user-info">
        <div class="container">
            <div class="row">

                <div class="col-xs-12 col-md-10 offset-md-1">
                    <img ~image1~ class="user-img"/>
                    ~name1~
                    <p>
                        ~bio1~
                    </p>
                    <button class="btn btn-sm btn-outline-secondary action-btn">
                        <i class="ion-plus-round"></i>
                        &nbsp;
                        Follow ~name2~
                    </button>
                </div>

            </div>
        </div>
    </div>

    <div class="container">
        <div class="row">

            <div class="col-xs-12 col-md-10 offset-md-1">
                <div class="articles-toggle">
                    <ul class="nav nav-pills outline-active">
                        <li class="nav-item">
                            <a class="nav-link active" href="">My Articles</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="">Favorited Articles</a>
                        </li>
                    </ul>
                </div>

                <div class="article-preview">
                    <div class="article-meta">
                        <a href="" ><img src="http://i.imgur.com/Qr71crq.jpg"/></a>
                        <div class="info">
                            <a href="" class="author">Eric Simons</a>
                            <span class="date">January 20th</span>
                        </div>
                        <button class="btn btn-outline-primary btn-sm pull-xs-right">
                            <i class="ion-heart"></i> 29
                        </button>
                    </div>
                    <a href="" class="preview-link">
                        <h1>How to build webapps that scale</h1>
                        <p>This is the description for the post.</p>
                        <span>Read more...</span>
                    </a>
                </div>

                <div class="article-preview">
                    <div class="article-meta">
                        <a href=""><img src="http://i.imgur.com/N4VcUeJ.jpg"/></a>
                        <div class="info">
                            <a href="" class="author">Albert Pai</a>
                            <span class="date">January 20th</span>
                        </div>
                        <button class="btn btn-outline-primary btn-sm pull-xs-right">
                            <i class="ion-heart"></i> 32
                        </button>
                    </div>
                    <a href="" class="preview-link">
                        <h1>The song you won't ever stop singing. No matter how hard you try.</h1>
                        <p>This is the description for the post.</p>
                        <span>Read more...</span>
                        <ul class="tag-list">
                            <li class="tag-default tag-pill tag-outline">Music</li>
                            <li class="tag-default tag-pill tag-outline">Song</li>
                        </ul>
                    </a>
                </div>


            </div>

        </div>
    </div>

</div>
"""

profileLoading_ =
  Proxy :: Proxy
         """<div class="profile-page">

    <div class="user-info">
        <div class="container">
            <div class="row">

                <div class="col-xs-12 col-md-10 offset-md-1">
                    <h4>Loading...</h4>
                    </div>
                    </div>
                    </div>
                    </div>
                    </div>
"""



profile :: forall s m lock payload. Korok s m => AnEvent m AuthState -> ProfileStatus -> Domable m lock payload
profile e (ProfileLoaded a b c) = profileLoaded e a b c
profile e ProfileLoading = profileLoading_ ~~ {}

profileLoaded :: forall s m lock payload. Korok s m => AnEvent m AuthState -> SingleProfile -> MultipleArticles -> MultipleArticles -> Domable m lock payload
profileLoaded
  currentUser
  { profile:
      { username
      , image
      , bio
      }
  }
  myArticles
  favoritedArticles = Deku.do
  profile_ ~~
    { image1: pure (D.Src := image)
    , name1: nut (D.h4_ [text_ username])
    , bio1: nut (maybe blank (\b -> D.h4_ [text_ b]) bio)
    , name2: nut (text_ username)
    }
